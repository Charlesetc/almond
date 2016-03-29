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

type method struct {
	name     string
	function block
}

type definition struct {
	name    string
	members []string
	methods []method
}

func hzl____dot___(as []*any, yield block) *any {
	a := as[0]
	member_name := *from_string(as[1])
	def := struct_definitions[a.hazelnut_type-1]
	for _, meth := range def.methods {
		if meth.name == member_name {
			return meth.function(append([]*any{a}, as[2:]...), yield)
		}
	}

	for i, name := range def.members {
		if name == member_name {
			return (*(*[]*any)(a.hazelnut_data))[i]
		}
	}
	panic(fmt.Sprintf("so such field in struct: %s", member_name))
}

func hzl____dot______equals___(as []*any, yield block) *any {
	a := as[0]
	member_name := *from_string(as[1])
	value := as[2]
	if a.hazelnut_type <= NUMBER_OF_TYPES {
		panic(".= must be called on a struct.")
	}
	def := struct_definitions[a.hazelnut_type-1]
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

func into_bool(b bool) *any {
	return into_any(BOOL, unsafe.Pointer(&b))
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

func hzl____equals______equals___(arguments []*any, yield block) *any {
	if len(arguments) != 2 {
		panic("Wrong number of arguments for == - not 2")
	}
	a := arguments[0]
	b := arguments[1]
	if a.hazelnut_type != b.hazelnut_type {
		return into_bool(false)
	}

	if a.hazelnut_type == INT {
		return into_bool(*(*int)(a.hazelnut_data) == *(*int)(b.hazelnut_data))
	} // else if a.hazelnut_type == STRING {
	return into_bool(*(*string)(a.hazelnut_data) == *(*string)(b.hazelnut_data))
}

func hzl____plus___(arguments []*any, yield block) *any {
	a := from_int(arguments[0])
	b := from_int(arguments[1])
	c := *a + *b
	return into_any(INT, unsafe.Pointer(&c))
}

func hzl_print(arguments []*any, yield block) *any {
	first := true
	for _, a := range arguments {
		if !first {
			fmt.Print(" ")
		}
		first = false

		if a.hazelnut_type == INT {
			fmt.Printf("%d", *(*int)(a.hazelnut_data))
		} else if a.hazelnut_type == FLOAT {
			fmt.Printf("%f", *(*float64)(a.hazelnut_data))
		} else if a.hazelnut_type == NIL {
			fmt.Printf("nil")
		} else if a.hazelnut_type == STRING {
			fmt.Printf("%s", *(*string)(a.hazelnut_data))
		} else if a.hazelnut_type == BOOL {
			fmt.Printf("%t", *(*bool)(a.hazelnut_data))
		} else if a.hazelnut_type == ARRAY {
			hzl_puts(*(*[]*any)(a.hazelnut_data), nil)
		} else { // Must be a struct
			def := struct_definitions[a.hazelnut_type-1]
			fmt.Printf("{%s: ", def.name)
			hzl_print(*(*[]*any)(a.hazelnut_data), nil)
			fmt.Print("}")
		}
	}
	return into_any(NIL, nil)
}

func hzl_puts(arguments []*any, yield block) *any {
	out := hzl_print(arguments, yield)
	fmt.Print("\n")
	return out
}
