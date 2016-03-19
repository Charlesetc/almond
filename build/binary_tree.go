package main

import "fmt"

// var struct_definitions []definition = []definition{}

type binary_tree struct {
	data []tagged_block
}

type tagged_block struct {
	tag      int
	function block
}

func (self *binary_tree) find(n int) (block, error) {
	var data tagged_block
	i := 1
	for i <= len(self.data) {
		fmt.Printf("i: %d\n", i)
		data = self.data[i-1]
		i *= 2
		if data.tag < n {
			if data.tag == -1 {
				break
			}
			i += 1
			fmt.Printf("great\n")
		} else if data.tag > n {
			fmt.Printf("less\n")
		} else {
			fmt.Printf("equal %d\n", n)
			return data.function, nil
		}
	}
	return nil, fmt.Errorf("Not found %d", n)
}

// // this is how it works:
// func main() {
// 	tree := binary_tree{
// 		data: []tagged_block{
// 			{4, nil},
// 			{1, nil}, {6, nil},
// 			{0, nil}, {3, nil}, {5, nil}, {8, nil},
// 		},
// 	}
// 	_, err := tree.find(6)
// 	if err != nil {
// 		fmt.Println(err)
// 	} else {
// 		fmt.Println("found")
// 	}
// }
