//
//  CeedNumerics
//
//  Created by Raphael Sebbe on 18/11/2018.
//  Copyright © 2018 Creaceed. All rights reserved.
//

import Foundation

public protocol NDimensionalArray: CustomStringConvertible {
	associatedtype Element: NValue
	associatedtype NativeIndex: Equatable
	associatedtype NativeIndexRange: Sequence where NativeIndexRange.Element == Self.NativeIndex
	associatedtype NativeResolvedSlice: NDimensionalResolvedSlice where NativeResolvedSlice.NativeIndex == Self.NativeIndex
	associatedtype Mask: NDimensionalArray where Mask.Element == Bool, Mask.NativeIndex == Self.NativeIndex
	typealias Vector = NVector<Element>
	typealias Storage = NStorage<Element>
	
	var dimension: Int { get }
	var shape: [Int] { get } // size is dimension
	var size: NativeIndex { get }
	//var slice: NativeResolvedSlice { get }
	
	var compact: Bool { get }
	var coalesceable: Bool { get }
	
	// More general API (not implemented)
//	func compact(in dimensions: ClosedRange<Int>)
//	func coalescable(in dimensions: ClosedRange<Int>)
	
	init(repeating value: Element, size: NativeIndex)
	init(storage: Storage, slice: NativeResolvedSlice)
	
	// Returns a independent copy with compact storage
//	func copy() -> Self
	func set(from: Self)
	
	// we don't define as vararg arrays, we let that up to the actual type to opt-out from array use (performance).
	subscript(index: [Int]) -> Element { get nonmutating set }
	subscript(index: NativeIndex) -> Element { get nonmutating set }
	var indices: NativeIndexRange { get }
	
//	internal func deriving() -> Self
}

// Some common API
extension NDimensionalArray {
	public init(size: NativeIndex) {
		self.init(repeating: .none, size: size)
	}
	public init(size: NativeIndex, generator: (_ index: NativeIndex) -> Element) {
		self.init(size: size)
		for i in indices {
			self[i] = generator(i)
		}
	}
	
	// Copy that is compact & coalescable, and with distinct storage from original
	public func copy() -> Self {
		let result = Self(size: size)
		result.set(from: self)
		return result
	}
	
	public subscript(mask: Mask) -> Vector {
		get {
			precondition(mask.size == size)
			let c = mask.trueCount
			let result = Vector(size: c)
			var i=0
			for index in mask.indices {
				guard mask[index] == true else { continue }
				result[i] = self[index]
				i += 1
			}
			return result
		}
		nonmutating set {
			precondition(mask.size == size)
			let c = mask.trueCount
			precondition(c == newValue.size)
			var i=0
			for index in mask.indices {
				guard mask[index] == true else { continue }
				self[index] = newValue[i]
				i += 1
			}
		}
	}
}


extension NDimensionalArray {
	// quickie to allocate result with same size as self.
	internal func _deriving(_ prep: (Self) -> ()) -> Self {
		let result = Self(repeating: .none, size: self.size)
		prep(result)
		return result
	}
	
	private func recursiveDescription(index: [Int]) -> String {
		var description = ""
		let dimi = index.count
		var first: Bool = false, last = false
		
		if index.count > 0 {
			first = (index.last! == 0)
			last = (index.last! == shape[index.count-1]-1)
			
		}
		
		if index.count > 0 {
			if first { description += "[" }
			if !first { description += " " }
		}
		
		if dimi == shape.count {
			description += "\(self[index])"
		} else {
			for i in 0..<shape[dimi] {
				description += recursiveDescription(index: index + [i])
			}
		}
		
		if index.count > 0 {
			if !last { description += "," }
			if !last && dimi == shape.count - 1 { description += "\n" }
			if last { description += "]" }
		}
		
		return description
	}
	
	public var description: String {
		get {
			let shapeDescr = shape.map {"\($0)"}.joined(separator: "×")
			return "(\(shapeDescr))" + recursiveDescription(index: [])
		}
	}
}

extension NDimensionalArray where Element == Bool {
	internal var trueCount: Int {
		var c = 0
		for i in self.indices { c += self[i] ? 1 : 0 }
		return c
	}
	public static prefix func !(rhs: Self) -> Self { return rhs._deriving { for i in rhs.indices { $0[i] = !rhs[i] } } }
	
}

public class DimensionalIterator: IteratorProtocol {
	private var shape: [Int]
	private var presentIndex: [Int]
	private var first = true
	private var dimension: Int { return shape.count }
	
	public init(shape: [Int]) {
		assert(shape.count > 0)
		assert(shape.allSatisfy { $0 > 0 })
		
		self.shape = shape
		self.presentIndex = [Int](repeating: 0, count: shape.count)
	}
	
	public func next() -> [Int]? {
		if presentIndex.isEmpty {
			return nil
		}
		if first {
			first = false
			return presentIndex
		}
		if !_incrementIndex(presentIndex.count - 1) {
			return nil
		}
		return presentIndex
	}
	
	private func _incrementIndex(_ dim: Int) -> Bool {
		if dim < 0 || dimension <= dim {
			return false
		}
		
		if presentIndex[dim] < shape[dim] - 1 {
			presentIndex[dim] += 1
		} else {
			if !_incrementIndex(dim - 1) {
				return false
			}
			presentIndex[dim] = 0
		}
		
		return true
	}
}

extension NDimensionalArray {
	public mutating func randomize(min: Element, max: Element, seed: Int = 0) {
		var generator = NSeededRandomNumberGenerator(seed: seed)
		for index in self.indices {
			self[index] = Element.random(min: min, max: max, using: &generator)
		}
	}
}
