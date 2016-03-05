package main

import "unsafe"

type ALMOND_TYPE int32

const (
	INT ALMOND_TYPE = iota
	FLOAT
	STRING
)

type any struct {
	almond_type ALMOND_TYPE
	almond_data unsafe.Pointer
}

func from_int(a *any) *int {
	if a.almond_type != INT {
		panic("from_int called with non-integer type")
	}
	return (*int)(a.almond_data)
}

func into_any(almond_type ALMOND_TYPE, almond_data unsafe.Pointer) *any {
	return &any{almond_type: almond_type,
		almond_data: almond_data}
}

func plus(arguments []*any, block func([]*any) *any) *any {
	a := from_int(arguments[0])
	b := from_int(arguments[1])
	c := *a + *b
	return into_any(INT, unsafe.Pointer(&c))
}
