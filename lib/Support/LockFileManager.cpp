//===--- LockFileManager.cpp - File-level Locking Utility------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "llvm/Support/LockFileManager.h"
#include "llvm/ADT/None.h"
#include "llvm/ADT/ScopeExit.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/Config/llvm-config.h"
#include "llvm/Support/Errc.h"
#include "llvm/Support/ErrorOr.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Signals.h"
#include "llvm/Support/raw_ostream.h"
#include <cerrno>
#include <ctime>
#include <memory>
#include <sys/stat.h>
#include <sys/types.h>
#include <system_error>
#include <tuple>
#if _WIN32
#include <windows.h>
#endif
#if LLVM_ON_UNIX
#include <unistd.h>
#endif

#if defined(__APPLE__) && defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && (__MAC_OS_X_VERSION_MIN_REQUIRED > 1050)
#define USE_OSX_GETHOSTUUID 1
#else
#define USE_OSX_GETHOSTUUID 0
#endif

#if USE_OSX_GETHOSTUUID
#include <uuid/uuid.h>
#endif

using namespace llvm;

/// \brief Attempt to read the lock file with the given name, if it exists.
///
/// \param LockFileName The name of the lock file to read.
///
/// \returns The process ID of the process that owns this lock file
Optional<std::pair<std::string, int> >
LockFileManager::readLockFile(StringRef LockFileName) {
  // Read the owning host and PID out of the lock file. If it appears that the
  // owning process is dead, the lock file is invalid.
  ErrorOr<std::unique_ptr<MemoryBuffer>> MBOrErr =
      MemoryBuffer::getFile(LockFileName);
  if (!MBOrErr) {
    sys::fs::remove(LockFileName);
    return None;
  }
  MemoryBuffer &MB = *MBOrErr.get();

  StringRef Hostname;
  StringRef PIDStr;
  std::tie(Hostname, PIDStr) = getToken(MB.getBuffer(), " ");
  PIDStr = PIDStr.substr(PIDStr.find_first_not_of(" "));
  int PID;
  if (!PIDStr.getAsInteger(10, PID)) {
    auto Owner = std::make_pair(std::string(Hostname), PID);
    if (processStillExecuting(Owner.first, Owner.second))
      return Owner;
  }

  // Delete the lock file. It's invalid anyway.
  sys::fs::remove(LockFileName);
  return None;
}

static std::error_code getHostID(SmallVectorImpl<char> &HostID) {
  HostID.clear();

#if USE_OSX_GETHOSTUUID
  // On OS X, use the more stable hardware UUID instead of hostname.
  struct timespec wait = {1, 0}; // 1 second.
  uuid_t uuid;
  if (gethostuuid(uuid, &wait) != 0)
    return std::error_code(errno, std::system_category());

  uuid_string_t UUIDStr;
  uuid_unparse(uuid, UUIDStr);
  StringRef UUIDRef(UUIDStr);
  HostID.append(UUIDRef.begin(), UUIDRef.end());

#elif LLVM_ON_UNIX
  char HostName[256];
  HostName[255] = 0;
  HostName[0] = 0;
  gethostname(HostName, 255);
  StringRef HostNameRef(HostName);
  HostID.append(HostNameRef.begin(), HostNameRef.end());

#else
  StringRef Dummy("localhost");
  HostID.append(Dummy.begin(), Dummy.end());
#endif

  return std::error_code();
}

bool LockFileManager::processStillExecuting(StringRef HostID, int PID) {
#if LLVM_ON_UNIX && !defined(__ANDROID__)
  SmallString<256> StoredHostID;
  if (getHostID(StoredHostID))
    return true; // Conservatively assume it's executing on error.

  // Check whether the process is dead. If so, we're done.
  if (StoredHostID == HostID && getsid(PID) == -1 && errno == ESRCH)
    return false;
#endif

  return true;
}

LockFileManager::LockFileManager(StringRef FileName)
{
  this->FileName = FileName;
  if (std::error_code EC = sys::fs::make_absolute(this->FileName)) {
    std::string S("failed to obtain absolute path for ");
    S.append(this->FileName.str());
    setError(EC, S);
    return;
  }
  LockFileName = this->FileName;
  LockFileName += ".lock";

  // If the lock file already exists, don't bother to try to create our own
  // lock file; it won't work anyway. Just figure out who owns this lock file.
  if ((Owner = readLockFile(LockFileName)))
    return;

  // Create a lock file that is unique to this instance.
  Expected<sys::fs::TempFile> Temp =
      sys::fs::TempFile::create(LockFileName + "-%%%%%%%%");
  if (!Temp) {
    std::error_code EC = errorToErrorCode(Temp.takeError());
    std::string S("failed to create unique file with prefix ");
    S.append(LockFileName.str());
    setError(EC, S);
    return;
  }
  UniqueLockFile = std::move(*Temp);

  // Make sure we discard the temporary file on exit.
  auto RemoveTempFile = llvm::make_scope_exit([&]() {
    if (Error E = UniqueLockFile->discard())
      setError(errorToErrorCode(std::move(E)));
  });

  // Write our process ID to our unique lock file.
  {
    SmallString<256> HostID;
    if (auto EC = getHostID(HostID)) {
      setError(EC, "failed to get host id");
      return;
    }

    raw_fd_ostream Out(UniqueLockFile->FD, /*shouldClose=*/false);
    Out << HostID << ' ';
#if LLVM_ON_UNIX
    Out << getpid();
#else
    Out << "1";
#endif
    Out.flush();

    if (Out.has_error()) {
      // We failed to write out PID, so report the error, remove the
      // unique lock file, and fail.
      std::string S("failed to write to ");
      S.append(UniqueLockFile->TmpName);
      setError(Out.error(), S);
      return;
    }
  }

  while (true) {
    // Create a link from the lock file name. If this succeeds, we're done.
    std::error_code EC =
        sys::fs::create_link(UniqueLockFile->TmpName, LockFileName);
    if (!EC) {
      RemoveTempFile.release();
      return;
    }

    if (EC != errc::file_exists) {
      std::string S("failed to create link ");
      raw_string_ostream OSS(S);
      OSS << LockFileName.str() << " to " << UniqueLockFile->TmpName;
      setError(EC, OSS.str());
      return;
    }

    // Someone else managed to create the lock file first. Read the process ID
    // from the lock file.
    if ((Owner = readLockFile(LockFileName)))
      return; // RemoveTempFile will delete out our unique lock file.

    if (!sys::fs::exists(LockFileName)) {
      // The previous owner released the lock file before we could read it.
      // Try to get ownership again.
      continue;
    }

    // There is a lock file that nobody owns; try to clean it up and get
    // ownership.
    if ((EC = sys::fs::remove(LockFileName))) {
      std::string S("failed to remove lockfile ");
      S.append(LockFileName.str());
      setError(EC, S);
      return;
    }
  }
}

LockFileManager::LockFileState LockFileManager::getState() const {
  if (Owner)
    return LFS_Shared;

  if (ErrorCode)
    return LFS_Error;

  return LFS_Owned;
}

std::string LockFileManager::getErrorMessage() const {
  if (ErrorCode) {
    std::string Str(ErrorDiagMsg);
    std::string ErrCodeMsg = ErrorCode.message();
    raw_string_ostream OSS(Str);
    if (!ErrCodeMsg.empty())
      OSS << ": " << ErrCodeMsg;
    return OSS.str();
  }
  return "";
}

LockFileManager::~LockFileManager() {
  if (getState() != LFS_Owned)
    return;

  // Since we own the lock, remove the lock file and our own unique lock file.
  sys::fs::remove(LockFileName);
  consumeError(UniqueLockFile->discard());
}

LockFileManager::WaitForUnlockResult LockFileManager::waitForUnlock() {
  if (getState() != LFS_Shared)
    return Res_Success;

#if _WIN32
  unsigned long Interval = 1;
#else
  struct timespec Interval;
  Interval.tv_sec = 0;
  Interval.tv_nsec = 1000000;
#endif
  // Don't wait more than 40s per iteration. Total timeout for the file
  // to appear is ~1.5 minutes.
  const unsigned MaxSeconds = 40;
  do {
    // Sleep for the designated interval, to allow the owning process time to
    // finish up and remove the lock file.
    // FIXME: Should we hook in to system APIs to get a notification when the
    // lock file is deleted?
#if _WIN32
    Sleep(Interval);
#else
    nanosleep(&Interval, nullptr);
#endif

    if (sys::fs::access(LockFileName.c_str(), sys::fs::AccessMode::Exist) ==
        errc::no_such_file_or_directory) {
      // If the original file wasn't created, somone thought the lock was dead.
      if (!sys::fs::exists(FileName))
        return Res_OwnerDied;
      return Res_Success;
    }

    // If the process owning the lock died without cleaning up, just bail out.
    if (!processStillExecuting((*Owner).first, (*Owner).second))
      return Res_OwnerDied;

    // Exponentially increase the time we wait for the lock to be removed.
#if _WIN32
    Interval *= 2;
#else
    Interval.tv_sec *= 2;
    Interval.tv_nsec *= 2;
    if (Interval.tv_nsec >= 1000000000) {
      ++Interval.tv_sec;
      Interval.tv_nsec -= 1000000000;
    }
#endif
  } while (
#if _WIN32
           Interval < MaxSeconds * 1000
#else
           Interval.tv_sec < (time_t)MaxSeconds
#endif
           );

  // Give up.
  return Res_Timeout;
}

std::error_code LockFileManager::unsafeRemoveLockFile() {
  return sys::fs::remove(LockFileName);
}
