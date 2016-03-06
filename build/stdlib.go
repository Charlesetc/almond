package main

import (
	"fmt"
	"unsafe"
)

type HAZELNUT_TYPE int32

const (
	INT HAZELNUT_TYPE = iota
	FLOAT
	STRING
	NIL
	BOOL
)

type any struct {
	hazelnut_type HAZELNUT_TYPE
	hazelnut_data unsafe.Pointer
}

func from_int(a *any) *int {
	if a.hazelnut_type != INT {
		panic("from_int called with non-integer type")
	}
	return (*int)(a.hazelnut_data)
}

func from_bool(a *any) bool {
	if a.hazelnut_type == BOOL {
		return *(*bool)(a.hazelnut_data)
	} else if a.hazelnut_type == NIL {
		return false
	}
	return true
}

func into_any(hazelnut_type HAZELNUT_TYPE, hazelnut_data unsafe.Pointer) *any {
	return &any{hazelnut_type: hazelnut_type,
		hazelnut_data: hazelnut_data}
}

func plus(arguments []*any, block func([]*any) *any) *any {
	a := from_int(arguments[0])
	b := from_int(arguments[1])
	c := *a + *b
	return into_any(INT, unsafe.Pointer(&c))
}

func puts(arguments []*any, block func([]*any) *any) *any {
	for _, a := range arguments {
		if a.hazelnut_type == INT {
			fmt.Printf("%d ", *(*int)(a.hazelnut_data))
		} else if a.hazelnut_type == FLOAT {
			fmt.Printf("%f ", *(*float64)(a.hazelnut_data))
		} else if a.hazelnut_type == NIL {
			fmt.Printf("nil")
		} else if a.hazelnut_type == BOOL {
			fmt.Printf("%t ", *(*bool)(a.hazelnut_data))
		}
	}
	fmt.Print("\n")
	return into_any(NIL, nil)
}
