/*
Copyright (c) 2018-present Creaceed SPRL and other CeedNumerics contributors.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Creaceed SPRL nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL CREACEED SPRL BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation


public struct XQuadraticIndexRange {
	public let rows, columns: Int
	public var row: Range<Int> { return 0..<rows }
	public var column: Range<Int> { return 0..<columns }
	
	public init(rows ar: Int, columns ac: Int) {
		rows = ar
		columns = ac
	}
//	public func makeIterator() -> XQuadraticIndexIterator {
//		return XQuadraticIndexIterator(start: (0,0), step: (1,1), end: (rows, columns))
//	}
//		public func makeIterator() -> XQuadraticIndexIteratorVariant {
//			return XQuadraticIndexIteratorVariant(sequence: self)
//		}
}


public struct XQuadraticIndexIterator: IteratorProtocol {
	private let start: (row: Int, column: Int)
	private let step: (row: Int, column: Int)
	private let end: (row: Int, column: Int)
	// internal state
	private var current: (row: Int, column: Int)
	private var done: Bool = false
	
	public init(start astart: (Int, Int), step astep: (Int, Int), end aend: (Int, Int)) {
		assert((aend.0 - astart.0) % astep.0 == 0)
		assert((aend.1 - astart.1) % astep.1 == 0)
		assert(abs(astep.0) > 0)
		assert(abs(astep.1) > 0)
		
		start = astart
		step = astep
		end = aend
		current = astart
		done = (astart == aend)
	}
	
	public mutating func next() -> (Int, Int)? {
		guard !done else { return nil }
		
		let loc = (current.row, current.column)
		current.column += step.column
		if current.column == end.column {
			current.column = start.column
			current.row += step.row
			done = (current.row == end.row)
		}
		return loc
	}
}

public struct XQuadraticIndexIteratorVariant: IteratorProtocol {
	let sequence: XQuadraticIndexRange
	var iterators: (Range<Int>.Iterator, Range<Int>.Iterator)
	var current: (Int, Int)
	var done: Bool
	//	var combined: Element
	
	init(sequence s: XQuadraticIndexRange) {
		sequence = s
		iterators = (sequence.row.makeIterator(), sequence.column.makeIterator())
		
		if let i0 = iterators.0.next(), let i1 = iterators.1.next() {
			done = false
			current.0 = i0
			current.1 = i1
		} else {
			done = true
			current.0 = 0
			current.1 = 0
		}
	}
	
	public mutating func next() -> (Int,Int)? {
		guard !done else { return nil }
		
		let loc = (current.0, current.1)
		
		if let i1 = iterators.1.next() {
			current.1 = i1
		} else {
			if let i0 = iterators.0.next() {
				current.0 = i0
				iterators.1 = sequence.column.makeIterator()
				current.1 = iterators.1.next()!
			} else {
				done = true
			}
		}
		
		return loc
	}
}







public protocol XQuadraticSequence: Sequence {
	associatedtype LinearSequence: Sequence
	//typealias Element = (LinearSequence.Element, LinearSequence.Element)
	
	var sequences: (LinearSequence, LinearSequence) { get }
//	static func combineDimensions(_: LinearSequence.Element, _: LinearSequence.Element) -> Element
	// this is to avoid using optional in iterator (but this value is not used)
	static func _defaultLinearSequenceElement() -> LinearSequence.Element
}
public struct XQuadraticIterator<Sequence: XQuadraticSequence>: IteratorProtocol {
	let sequence: Sequence
	var iterators: (Sequence.LinearSequence.Iterator, Sequence.LinearSequence.Iterator)
	var current: (Sequence.LinearSequence.Element, Sequence.LinearSequence.Element)
	var done: Bool
	
	init(sequence s: Sequence) {
		sequence = s
		iterators = (sequence.sequences.0.makeIterator(), sequence.sequences.1.makeIterator())
		
		if let i0 = iterators.0.next(), let i1 = iterators.1.next() {
			done = false
			current.0 = i0
			current.1 = i1
		} else {
			done = true
			current.0 = Sequence._defaultLinearSequenceElement()
			current.1 = Sequence._defaultLinearSequenceElement()
		}
	}
	
	public mutating func next() -> (Sequence.LinearSequence.Element, Sequence.LinearSequence.Element)? {
		guard !done else { return nil }
		
//		let loc = Sequence.combineDimensions(current.0, current.1)
		let loc = (current.0, current.1)
		
		if let i1 = iterators.1.next() {
			current.1 = i1
		} else {
			if let i0 = iterators.0.next() {
				current.0 = i0
				iterators.1 = sequence.sequences.1.makeIterator()
				current.1 = iterators.1.next()!
			} else {
				done = true
			}
		}
		
		return loc
	}
}
extension XQuadraticSequence {
	public func makeIterator() -> XQuadraticIterator<Self> {
		return XQuadraticIterator(sequence: self)
	}
}
extension XQuadraticSequence where Self.LinearSequence.Element == Int {
	public static func _defaultLinearSequenceElement() -> Int { return 0 }
}

extension XQuadraticIndexRange: XQuadraticSequence {
	
//	public typealias Element = (Int, Int)
	public typealias LinearSequence = Range<Int>
	public typealias Iterator = XQuadraticIterator<XQuadraticIndexRange>
	public var sequences: (Range<Int>, Range<Int>) { return (row, column) }
//	public static func combineDimensions(_ r: Int, _ c: Int) -> (Int, Int) {
//		return (r,c)
//	}
}
