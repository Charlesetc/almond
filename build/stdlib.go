package main

import (
	"fmt"
	"unsafe"
)

type HAZELNUT_TYPE int32

type block func([]*any, block) *any

const NUMBER_OF_TYPES HAZELNUT_TYPE = 6

const (
	INT HAZELNUT_TYPE = iota
	FLOAT
	STRING
	NIL
	BOOL
	ARRAY
)

type any struct {
	hazelnut_type HAZELNUT_TYPE
	hazelnut_data unsafe.Pointer
}

type definition struct {
	members []string
}

func hzl____dot___(as []*any, block func([]*any) *any) *any {
	a := as[0]
	member_name := *from_string(as[1])
	if a.hazelnut_type <= NUMBER_OF_TYPES {
		panic(". must be called on a struct.")
	}
	def := struct_definitions[a.hazelnut_type-(NUMBER_OF_TYPES+1)]
	for i, name := range def.members {
		if name == member_name {
			return (*(*[]*any)(a.hazelnut_data))[i]
		}
	}
	panic(fmt.Sprintf("so such field in struct: %s", member_name))
}

func hzl____dot______equals___(as []*any, block func([]*any) *any) *any {
	a := as[0]
	member_name := *from_string(as[1])
	value := as[2]
	if a.hazelnut_type <= NUMBER_OF_TYPES {
		panic(".= must be called on a struct.")
	}
	def := struct_definitions[a.hazelnut_type-(NUMBER_OF_TYPES+1)]
	for i, name := range def.members {
		if name == member_name {
			(*(*[]*any)(a.hazelnut_data))[i] = value
			return into_any(NIL, nil)
		}
	}
	panic(fmt.Sprintf("so such field in struct: %s", member_name))
}

func from_int(a *any) *int {
	if a.hazelnut_type != INT {
		panic("from_int called with non-integer type")
	}
	return (*int)(a.hazelnut_data)
}

func from_string(a *any) *string {
	if a.hazelnut_type != STRING {
		panic("from_int called with non-string type")
	}
	return (*string)(a.hazelnut_data)
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

func hzl____plus___(arguments []*any, block func([]*any) *any) *any {
	a := from_int(arguments[0])
	b := from_int(arguments[1])
	c := *a + *b
	return into_any(INT, unsafe.Pointer(&c))
}

func hzl_puts(arguments []*any, block func([]*any) *any) *any {
	for _, a := range arguments {
		if a.hazelnut_type == INT {
			fmt.Printf("%d ", *(*int)(a.hazelnut_data))
		} else if a.hazelnut_type == FLOAT {
			fmt.Printf("%f ", *(*float64)(a.hazelnut_data))
		} else if a.hazelnut_type == NIL {
			fmt.Printf("nil")
		} else if a.hazelnut_type == STRING {
			fmt.Printf("%s ", *(*string)(a.hazelnut_data))
		} else if a.hazelnut_type == BOOL {
			fmt.Printf("%t ", *(*bool)(a.hazelnut_data))
		} else if a.hazelnut_type == ARRAY {
			hzl_puts(*(*[]*any)(a.hazelnut_data), nil)
		} else {
			fmt.Print("{\n")
			hzl_puts(*(*[]*any)(a.hazelnut_data), nil)
			fmt.Print("}")
		}
	}
	fmt.Print("\n")
	return into_any(NIL, nil)
}
