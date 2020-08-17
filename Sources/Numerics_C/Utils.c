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

#include "Utils.h"
#include <stdio.h>

#define MAX_RANK 16

void strided_set_float(long rank, long const *shape, size_t bpe, float *dest, size_t const *dstrides, float const *src, size_t const *sstrides) {
//	printf("hello from C\n");
	
//	long dsteps[MAX_RANK] = {0};
//	long ssteps[MAX_RANK] = {0};
//
	struct {
//		long acc;
		long coordinate;
	} it[MAX_RANK] = {0};
	
//	ssteps[0] = shape[0];
//	dsteps[0] = shape[0];
//
//	for(long i=1; i<rank; i++) {
//		ssteps[i] = shape[i] * ssteps[i-1];
//		dsteps[i] = shape[i] * dsteps[i-1];
//	}
	
	
	long spos = 0;
	long dpos = 0;
//	counter = 0;
	long count = rank > 0 ? 1 : 0;
	
	for(long dim=0; dim<rank; dim++) {
		count *= shape[dim];
	}
	
	if(count == 0) return;
	
	for (;;) {
		dest[dpos] = src[spos];
		
		for(long dim=rank-1; dim >= 0; dim--) {
			it[dim].coordinate += 1;
			spos += sstrides[dim];
			dpos += dstrides[dim];
			
			if (it[dim].coordinate == shape[dim]) {
				// dim is over, move to previous (or stop)
				spos -= shape[dim] * sstrides[dim];
				dpos -= shape[dim] * dstrides[dim];
				it[dim].coordinate = 0;
				
				if(dim == 0) return;
				continue;
			}
			break;
		}
	}
}

void strided_set_gen(long rank, long const *shape, size_t bpe, void *dest_v, size_t const *dstrides, void const *src_v, size_t const *sstrides) {
//	printf("hello from C\n");
	
//	long dsteps[MAX_RANK] = {0};
//	long ssteps[MAX_RANK] = {0};
//
	struct {
//		long acc;
		long coordinate;
		size_t sstride; // bpe adjusted
		size_t dstride;
	} it[MAX_RANK] = {0};
	
	uint8_t const *src = src_v;
	uint8_t *dest = dest_v;
	
//	ssteps[0] = shape[0];
//	dsteps[0] = shape[0];
//
//	for(long i=1; i<rank; i++) {
//		ssteps[i] = shape[i] * ssteps[i-1];
//		dsteps[i] = shape[i] * dsteps[i-1];
//	}
	
	
	long spos = 0;
	long dpos = 0;
//	counter = 0;
	long count = rank > 0 ? 1 : 0;
	
	for(long dim=0; dim<rank; dim++) {
		count *= shape[dim];
		it[dim].sstride = sstrides[dim] * bpe;
		it[dim].dstride = dstrides[dim] * bpe;
	}
	
	if(count == 0) return;
	
	for (;;) {
		for(int i=0; i<bpe; i++) dest[dpos+i] = src[spos+i];
		
		for(long dim=rank-1; dim >= 0; dim--) {
			it[dim].coordinate += 1;
			spos += it[dim].sstride;
			dpos += it[dim].dstride;
			
			if (it[dim].coordinate == shape[dim]) {
				// dim is over, move to previous (or stop)
				spos -= shape[dim] * it[dim].sstride;
				dpos -= shape[dim] * it[dim].dstride;
				it[dim].coordinate = 0;
				
				if(dim == 0) return;
				continue;
			}
			break;
		}
	}
}
