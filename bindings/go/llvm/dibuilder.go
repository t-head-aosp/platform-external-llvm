//===- dibuilder.go - Bindings for DIBuilder ------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines bindings for the DIBuilder class.
//
//===----------------------------------------------------------------------===//

package llvm

/*
#include "DIBuilderBindings.h"
#include <stdlib.h>
*/
import "C"

import (
	"debug/dwarf"
	"unsafe"
)

type DwarfTag uint32

const (
	DW_TAG_lexical_block   DwarfTag = 0x0b
	DW_TAG_compile_unit    DwarfTag = 0x11
	DW_TAG_variable        DwarfTag = 0x34
	DW_TAG_base_type       DwarfTag = 0x24
	DW_TAG_pointer_type    DwarfTag = 0x0F
	DW_TAG_structure_type  DwarfTag = 0x13
	DW_TAG_subroutine_type DwarfTag = 0x15
	DW_TAG_file_type       DwarfTag = 0x29
	DW_TAG_subprogram      DwarfTag = 0x2E
	DW_TAG_auto_variable   DwarfTag = 0x100
	DW_TAG_arg_variable    DwarfTag = 0x101
)

const (
	FlagPrivate = 1 << iota
	FlagProtected
	FlagFwdDecl
	FlagAppleBlock
	FlagBlockByrefStruct
	FlagVirtual
	FlagArtificial
	FlagExplicit
	FlagPrototyped
	FlagObjcClassComplete
	FlagObjectPointer
	FlagVector
	FlagStaticMember
	FlagIndirectVariable
)

type DwarfLang uint32

const (
	// http://dwarfstd.org/ShowIssue.php?issue=101014.1&type=open
	DW_LANG_Go DwarfLang = 0x0016
)

type DwarfTypeEncoding uint32

const (
	DW_ATE_address         DwarfTypeEncoding = 0x01
	DW_ATE_boolean         DwarfTypeEncoding = 0x02
	DW_ATE_complex_float   DwarfTypeEncoding = 0x03
	DW_ATE_float           DwarfTypeEncoding = 0x04
	DW_ATE_signed          DwarfTypeEncoding = 0x05
	DW_ATE_signed_char     DwarfTypeEncoding = 0x06
	DW_ATE_unsigned        DwarfTypeEncoding = 0x07
	DW_ATE_unsigned_char   DwarfTypeEncoding = 0x08
	DW_ATE_imaginary_float DwarfTypeEncoding = 0x09
	DW_ATE_packed_decimal  DwarfTypeEncoding = 0x0a
	DW_ATE_numeric_string  DwarfTypeEncoding = 0x0b
	DW_ATE_edited          DwarfTypeEncoding = 0x0c
	DW_ATE_signed_fixed    DwarfTypeEncoding = 0x0d
	DW_ATE_unsigned_fixed  DwarfTypeEncoding = 0x0e
	DW_ATE_decimal_float   DwarfTypeEncoding = 0x0f
	DW_ATE_UTF             DwarfTypeEncoding = 0x10
	DW_ATE_lo_user         DwarfTypeEncoding = 0x80
	DW_ATE_hi_user         DwarfTypeEncoding = 0xff
)

// DIBuilder is a wrapper for the LLVM DIBuilder class.
type DIBuilder struct {
	ref C.LLVMDIBuilderRef
	m   Module
}

// NewDIBuilder creates a new DIBuilder, associated with the given module.
func NewDIBuilder(m Module) *DIBuilder {
	d := C.LLVMCreateDIBuilder(m.C)
	return &DIBuilder{ref: d, m: m}
}

// Destroy destroys the DIBuilder.
func (d *DIBuilder) Destroy() {
	C.LLVMDisposeDIBuilder(d.ref)
}

// FInalize finalizes the debug information generated by the DIBuilder.
func (d *DIBuilder) Finalize() {
	C.LLVMDIBuilderFinalize(d.ref)
}

// DICompileUnit holds the values for creating compile unit debug metadata.
type DICompileUnit struct {
	Language       DwarfLang
	File           string
	Dir            string
	Producer       string
	Optimized      bool
	Flags          string
	RuntimeVersion int
}

// CreateCompileUnit creates compile unit debug metadata.
func (d *DIBuilder) CreateCompileUnit(cu DICompileUnit) Metadata {
	file := C.CString(cu.File)
	defer C.free(unsafe.Pointer(file))
	dir := C.CString(cu.Dir)
	defer C.free(unsafe.Pointer(dir))
	producer := C.CString(cu.Producer)
	defer C.free(unsafe.Pointer(producer))
	flags := C.CString(cu.Flags)
	defer C.free(unsafe.Pointer(flags))
	result := C.LLVMDIBuilderCreateCompileUnit(
		d.ref,
		C.LLVMDWARFSourceLanguage(cu.Language),
		C.LLVMDIBuilderCreateFile(d.ref, file, C.size_t(len(cu.File)), dir, C.size_t(len(cu.Dir))),
		producer, C.size_t(len(cu.Producer)),
		C.LLVMBool(boolToCInt(cu.Optimized)),
		flags, C.size_t(len(cu.Flags)),
		C.unsigned(cu.RuntimeVersion),
		/*SplitName=*/ nil, 0,
		C.LLVMDWARFEmissionFull,
		/*DWOId=*/ 0,
		/*SplitDebugInlining*/ C.LLVMBool(boolToCInt(true)),
		/*DebugInfoForProfiling*/ C.LLVMBool(boolToCInt(false)),
	)
	return Metadata{C: result}
}

// CreateFile creates file debug metadata.
func (d *DIBuilder) CreateFile(filename, dir string) Metadata {
	cfilename := C.CString(filename)
	defer C.free(unsafe.Pointer(cfilename))
	cdir := C.CString(dir)
	defer C.free(unsafe.Pointer(cdir))
	result := C.LLVMDIBuilderCreateFile(d.ref,
		cfilename, C.size_t(len(filename)),
		cdir, C.size_t(len(dir)))
	return Metadata{C: result}
}

// DILexicalBlock holds the values for creating lexical block debug metadata.
type DILexicalBlock struct {
	File   Metadata
	Line   int
	Column int
}

// CreateLexicalBlock creates lexical block debug metadata.
func (d *DIBuilder) CreateLexicalBlock(diScope Metadata, b DILexicalBlock) Metadata {
	result := C.LLVMDIBuilderCreateLexicalBlock(
		d.ref,
		diScope.C,
		b.File.C,
		C.unsigned(b.Line),
		C.unsigned(b.Column),
	)
	return Metadata{C: result}
}

func (d *DIBuilder) CreateLexicalBlockFile(diScope Metadata, diFile Metadata, discriminator int) Metadata {
	result := C.LLVMDIBuilderCreateLexicalBlockFile(d.ref, diScope.C, diFile.C,
		C.unsigned(discriminator))
	return Metadata{C: result}
}

// DIFunction holds the values for creating function debug metadata.
type DIFunction struct {
	Name         string
	LinkageName  string
	File         Metadata
	Line         int
	Type         Metadata
	LocalToUnit  bool
	IsDefinition bool
	ScopeLine    int
	Flags        int
	Optimized    bool
}

// CreateFunction creates function debug metadata.
func (d *DIBuilder) CreateFunction(diScope Metadata, f DIFunction) Metadata {
	name := C.CString(f.Name)
	defer C.free(unsafe.Pointer(name))
	linkageName := C.CString(f.LinkageName)
	defer C.free(unsafe.Pointer(linkageName))
	result := C.LLVMDIBuilderCreateFunction(
		d.ref,
		diScope.C,
		name,
		linkageName,
		f.File.C,
		C.unsigned(f.Line),
		f.Type.C,
		boolToCInt(f.LocalToUnit),
		boolToCInt(f.IsDefinition),
		C.unsigned(f.ScopeLine),
		C.unsigned(f.Flags),
		boolToCInt(f.Optimized),
	)
	return Metadata{C: result}
}

// DIAutoVariable holds the values for creating auto variable debug metadata.
type DIAutoVariable struct {
	Name           string
	File           Metadata
	Line           int
	Type           Metadata
	AlwaysPreserve bool
	Flags          int
	AlignInBits    uint32
}

// CreateAutoVariable creates local variable debug metadata.
func (d *DIBuilder) CreateAutoVariable(scope Metadata, v DIAutoVariable) Metadata {
	name := C.CString(v.Name)
	defer C.free(unsafe.Pointer(name))
	result := C.LLVMDIBuilderCreateAutoVariable(
		d.ref,
		scope.C,
		name,
		v.File.C,
		C.unsigned(v.Line),
		v.Type.C,
		boolToCInt(v.AlwaysPreserve),
		C.unsigned(v.Flags),
		C.uint32_t(v.AlignInBits),
	)
	return Metadata{C: result}
}

// DIParameterVariable holds the values for creating parameter variable debug metadata.
type DIParameterVariable struct {
	Name           string
	File           Metadata
	Line           int
	Type           Metadata
	AlwaysPreserve bool
	Flags          int

	// ArgNo is the 1-based index of the argument in the function's
	// parameter list.
	ArgNo int
}

// CreateParameterVariable creates parameter variable debug metadata.
func (d *DIBuilder) CreateParameterVariable(scope Metadata, v DIParameterVariable) Metadata {
	name := C.CString(v.Name)
	defer C.free(unsafe.Pointer(name))
	result := C.LLVMDIBuilderCreateParameterVariable(
		d.ref,
		scope.C,
		name,
		C.unsigned(v.ArgNo),
		v.File.C,
		C.unsigned(v.Line),
		v.Type.C,
		boolToCInt(v.AlwaysPreserve),
		C.unsigned(v.Flags),
	)
	return Metadata{C: result}
}

// DIBasicType holds the values for creating basic type debug metadata.
type DIBasicType struct {
	Name       string
	SizeInBits uint64
	Encoding   DwarfTypeEncoding
}

// CreateBasicType creates basic type debug metadata.
func (d *DIBuilder) CreateBasicType(t DIBasicType) Metadata {
	name := C.CString(t.Name)
	defer C.free(unsafe.Pointer(name))
	result := C.LLVMDIBuilderCreateBasicType(
		d.ref,
		name,
		C.size_t(len(t.Name)),
		C.unsigned(t.SizeInBits),
		C.unsigned(t.Encoding),
	)
	return Metadata{C: result}
}

// DIPointerType holds the values for creating pointer type debug metadata.
type DIPointerType struct {
	Pointee     Metadata
	SizeInBits  uint64
	AlignInBits uint32 // optional
	AddressSpace uint32
	Name        string // optional
}

// CreatePointerType creates a type that represents a pointer to another type.
func (d *DIBuilder) CreatePointerType(t DIPointerType) Metadata {
	name := C.CString(t.Name)
	defer C.free(unsafe.Pointer(name))
	result := C.LLVMDIBuilderCreatePointerType(
		d.ref,
		t.Pointee.C,
		C.unsigned(t.SizeInBits),
		C.unsigned(t.AlignInBits),
		C.unsigned(t.AddressSpace),
		name,
		C.size_t(len(t.Name)),
	)
	return Metadata{C: result}
}

// DISubroutineType holds the values for creating subroutine type debug metadata.
type DISubroutineType struct {
	// File is the file in which the subroutine type is defined.
	File Metadata

	// Parameters contains the subroutine parameter types,
	// including the return type at the 0th index.
	Parameters []Metadata

	Flags int
}

// CreateSubroutineType creates subroutine type debug metadata.
func (d *DIBuilder) CreateSubroutineType(t DISubroutineType) Metadata {
	params, length := llvmMetadataRefs(t.Parameters)
	result := C.LLVMDIBuilderCreateSubroutineType(
		d.ref,
		t.File.C,
		params,
		length,
		C.LLVMDIFlags(t.Flags),
	)
	return Metadata{C: result}
}

// DIStructType holds the values for creating struct type debug metadata.
type DIStructType struct {
	Name        string
	File        Metadata
	Line        int
	SizeInBits  uint64
	AlignInBits uint32
	Flags       int
	DerivedFrom Metadata
	Elements    []Metadata
	VTableHolder Metadata // optional
	UniqueID     string
}

// CreateStructType creates struct type debug metadata.
func (d *DIBuilder) CreateStructType(scope Metadata, t DIStructType) Metadata {
	elements, length := llvmMetadataRefs(t.Elements)
	name := C.CString(t.Name)
	uniqueID := C.CString(t.UniqueID)
	defer C.free(unsafe.Pointer(name))
	defer C.free(unsafe.Pointer(uniqueID))
	result := C.LLVMDIBuilderCreateStructType(
		d.ref,
		scope.C,
		name,
		C.size_t(len(t.Name)),
		t.File.C,
		C.unsigned(t.Line),
		C.unsigned(t.SizeInBits),
		C.unsigned(t.AlignInBits),
		C.LLVMDIFlags(t.Flags),
		t.DerivedFrom.C,
		elements,
		length,
		C.unsigned(0), // Optional Objective-C runtime version.
		t.VTableHolder.C,
		uniqueID,
		C.uint64_t(len(t.UniqueID)),
	)
	return Metadata{C: result}
}

// DIReplaceableCompositeType holds the values for creating replaceable
// composite type debug metadata.
type DIReplaceableCompositeType struct {
	Tag         dwarf.Tag
	Name        string
	File        Metadata
	Line        int
	RuntimeLang int
	SizeInBits  uint64
	AlignInBits uint32
	Flags       int
	UniqueID    string
}

// CreateReplaceableCompositeType creates replaceable composite type debug metadata.
func (d *DIBuilder) CreateReplaceableCompositeType(scope Metadata, t DIReplaceableCompositeType) Metadata {
	name := C.CString(t.Name)
	uniqueID := C.CString(t.UniqueID)
	defer C.free(unsafe.Pointer(name))
	defer C.free(unsafe.Pointer(uniqueID))
	result := C.LLVMDIBuilderCreateReplaceableCompositeType(
		d.ref,
		C.unsigned(t.Tag),
		name,
		C.size_t(len(t.Name)),
		scope.C,
		t.File.C,
		C.unsigned(t.Line),
		C.unsigned(t.RuntimeLang),
		C.unsigned(t.SizeInBits),
		C.unsigned(t.AlignInBits),
		C.LLVMDIFlags(t.Flags),
		uniqueID,
		C.size_t(len(t.UniqueID)),
	)
	return Metadata{C: result}
}

// DIMemberType holds the values for creating member type debug metadata.
type DIMemberType struct {
	Name         string
	File         Metadata
	Line         int
	SizeInBits   uint64
	AlignInBits  uint32
	OffsetInBits uint64
	Flags        int
	Type         Metadata
}

// CreateMemberType creates struct type debug metadata.
func (d *DIBuilder) CreateMemberType(scope Metadata, t DIMemberType) Metadata {
	name := C.CString(t.Name)
	defer C.free(unsafe.Pointer(name))
	result := C.LLVMDIBuilderCreateMemberType(
		d.ref,
		scope.C,
		name,
		C.size_t(len(t.Name)),
		t.File.C,
		C.unsigned(t.Line),
		C.unsigned(t.SizeInBits),
		C.unsigned(t.AlignInBits),
		C.unsigned(t.OffsetInBits),
		C.LLVMDIFlags(t.Flags),
		t.Type.C,
	)
	return Metadata{C: result}
}

// DISubrange describes an integer value range.
type DISubrange struct {
	Lo    int64
	Count int64
}

// DIArrayType holds the values for creating array type debug metadata.
type DIArrayType struct {
	SizeInBits  uint64
	AlignInBits uint32
	ElementType Metadata
	Subscripts  []DISubrange
}

// CreateArrayType creates struct type debug metadata.
func (d *DIBuilder) CreateArrayType(t DIArrayType) Metadata {
	subscriptsSlice := make([]Metadata, len(t.Subscripts))
	for i, s := range t.Subscripts {
		subscriptsSlice[i] = d.getOrCreateSubrange(s.Lo, s.Count)
	}
	subscripts, length := llvmMetadataRefs(subscriptsSlice)
	result := C.LLVMDIBuilderCreateArrayType(
		d.ref,
		C.unsigned(t.SizeInBits),
		C.unsigned(t.AlignInBits),
		t.ElementType.C,
		subscripts,
		length,
	)
	return Metadata{C: result}
}

// DITypedef holds the values for creating typedef type debug metadata.
type DITypedef struct {
	Type    Metadata
	Name    string
	File    Metadata
	Line    int
	Context Metadata
}

// CreateTypedef creates typedef type debug metadata.
func (d *DIBuilder) CreateTypedef(t DITypedef) Metadata {
	name := C.CString(t.Name)
	defer C.free(unsafe.Pointer(name))
	result := C.LLVMDIBuilderCreateTypedef(
		d.ref,
		t.Type.C,
		name,
		t.File.C,
		C.unsigned(t.Line),
		t.Context.C,
	)
	return Metadata{C: result}
}

// getOrCreateSubrange gets a metadata node for the specified subrange,
// creating if required.
func (d *DIBuilder) getOrCreateSubrange(lo, count int64) Metadata {
	result := C.LLVMDIBuilderGetOrCreateSubrange(d.ref, C.int64_t(lo), C.int64_t(count))
	return Metadata{C: result}
}

// getOrCreateArray gets a metadata node containing the specified values,
// creating if required.
func (d *DIBuilder) getOrCreateArray(values []Metadata) Metadata {
	if len(values) == 0 {
		return Metadata{}
	}
	data, length := llvmMetadataRefs(values)
	result := C.LLVMDIBuilderGetOrCreateArray(d.ref, data, C.size_t(length))
	return Metadata{C: result}
}

// getOrCreateTypeArray gets a metadata node for a type array containing the
// specified values, creating if required.
func (d *DIBuilder) getOrCreateTypeArray(values []Metadata) Metadata {
	if len(values) == 0 {
		return Metadata{}
	}
	data, length := llvmMetadataRefs(values)
	result := C.LLVMDIBuilderGetOrCreateTypeArray(d.ref, data, C.size_t(length))
	return Metadata{C: result}
}

// CreateExpression creates a new descriptor for the specified
// variable which has a complex address expression for its address.
func (d *DIBuilder) CreateExpression(addr []int64) Metadata {
	var data *C.int64_t
	if len(addr) > 0 {
		data = (*C.int64_t)(unsafe.Pointer(&addr[0]))
	}
	result := C.LLVMDIBuilderCreateExpression(d.ref, data, C.size_t(len(addr)))
	return Metadata{C: result}
}

// InsertDeclareAtEnd inserts a call to llvm.dbg.declare at the end of the
// specified basic block for the given value and associated debug metadata.
func (d *DIBuilder) InsertDeclareAtEnd(v Value, diVarInfo, expr Metadata, bb BasicBlock) Value {
	result := C.LLVMDIBuilderInsertDeclareAtEnd(d.ref, v.C, diVarInfo.C, expr.C, bb.C)
	return Value{C: result}
}

// InsertValueAtEnd inserts a call to llvm.dbg.value at the end of the
// specified basic block for the given value and associated debug metadata.
func (d *DIBuilder) InsertValueAtEnd(v Value, diVarInfo, expr Metadata, bb BasicBlock) Value {
	result := C.LLVMDIBuilderInsertValueAtEnd(d.ref, v.C, diVarInfo.C, expr.C, bb.C)
	return Value{C: result}
}

func boolToCInt(v bool) C.int {
	if v {
		return 1
	}
	return 0
}
