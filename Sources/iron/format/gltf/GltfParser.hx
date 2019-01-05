package iron.format.gltf;

class GltfParser {

	public var posa:kha.arrays.Int16Array = null;
	public var nora:kha.arrays.Int16Array = null;
	public var texa:kha.arrays.Int16Array = null;
	public var inda:kha.arrays.Uint32Array = null;
	public var name = "";

	public function new(blob:kha.Blob) {
		// Prototype only, will collapse on anything more complex
		var format:TGLTF = haxe.Json.parse(blob.toString());

		var mesh = format.meshes[0];
		var prim = mesh.primitives[0];

		var a = format.accessors[prim.indices];
		var v = format.bufferViews[a.bufferView];
		var buf = format.buffers[v.buffer];
		var bytes:haxe.io.Bytes = null;
		var tag = "data:application/octet-stream;base64,";
		if (StringTools.startsWith(buf.uri, tag)) {
			bytes = haxe.crypto.Base64.decode(buf.uri.substr(tag.length));
		}
		else {
			// uri points to external blob
		}
		if (bytes == null) return;
		var b = kha.Blob.fromBytes(bytes);

		var elemSize = v.byteLength / a.count;
		switch (elemSize) {
		case 1: inda = readU8Array(format, b, a);
		case 2: inda = readU16Array(format, b, a);
		default: inda = readU32Array(format, b, a);
		}
		var posa32 = readF32Array(format, b, format.accessors[prim.attributes.POSITION]);
		var nora32 = readF32Array(format, b, format.accessors[prim.attributes.NORMAL]);
		var texa32 = prim.attributes.TEXCOORD_0 != null ? readF32Array(format, b, format.accessors[prim.attributes.TEXCOORD_0]) : null;

		// Pack into 16bit
		var verts = Std.int(posa32.length / 3);
		posa = new kha.arrays.Int16Array(verts * 4);
		nora = new kha.arrays.Int16Array(verts * 2);
		texa = texa32 != null ? new kha.arrays.Int16Array(verts * 2) : null;
		for (i in 0...verts) {
			posa[i * 4    ] = Std.int(posa32[i * 3    ] * 32767);
			posa[i * 4 + 1] = Std.int(posa32[i * 3 + 1] * 32767);
			posa[i * 4 + 2] = Std.int(posa32[i * 3 + 2] * 32767);
			posa[i * 4 + 3] = Std.int(nora32[i * 3 + 2] * 32767);
			nora[i * 2    ] = Std.int(nora32[i * 3    ] * 32767);
			nora[i * 2 + 1] = Std.int(nora32[i * 3 + 1] * 32767);
			if (texa != null) {
				texa[i * 2    ] = Std.int(texa32[i * 2    ] * 32767);
				texa[i * 2 + 1] = Std.int(texa32[i * 2 + 1] * 32767);
			}
		}
	}

	function readU8Array(format:TGLTF, b:kha.Blob, a:TAccessor):kha.arrays.Uint32Array {
		var v = format.bufferViews[a.bufferView];
		var ar = new kha.arrays.Uint32Array(v.byteLength);
		var pos = v.byteOffset;
		var i = 0;
		while (pos < v.byteOffset + v.byteLength) {
			ar[i] = b.readU8(pos);
			pos += 1;
			i++;
		}
		return ar;
	}

	function readU16Array(format:TGLTF, b:kha.Blob, a:TAccessor):kha.arrays.Uint32Array {
		var v = format.bufferViews[a.bufferView];
		var ar = new kha.arrays.Uint32Array(Std.int(v.byteLength / 2));
		var pos = v.byteOffset;
		var i = 0;
		while (pos < v.byteOffset + v.byteLength) {
			ar[i] = b.readU16LE(pos);
			pos += 2;
			i++;
		}
		return ar;
	}

	function readU32Array(format:TGLTF, b:kha.Blob, a:TAccessor):kha.arrays.Uint32Array {
		var v = format.bufferViews[a.bufferView];
		var ar = new kha.arrays.Uint32Array(Std.int(v.byteLength / 4));
		var pos = v.byteOffset;
		var i = 0;
		while (pos < v.byteOffset + v.byteLength) {
			ar[i] = b.readU32LE(pos);
			pos += 4;
			i++;
		}
		return ar;
	}

	function readF32Array(format:TGLTF, b:kha.Blob, a:TAccessor):kha.arrays.Float32Array {
		var v = format.bufferViews[a.bufferView];
		var ar = new kha.arrays.Float32Array(Std.int(v.byteLength / 4));
		var pos = v.byteOffset;
		var i = 0;
		while (pos < v.byteOffset + v.byteLength) {
			ar[i] = b.readF32LE(pos);
			pos += 4;
			i++;
		}
		return ar;
	}
}

typedef TGLTF = {
	var accessors:Array<TAccessor>;
	var bufferViews:Array<TBufferView>;
	var buffers:Array<TBuffer>;
	var meshes:Array<TMesh>;
}

typedef TAccessor = {
	var bufferView:Int;
	var componentType:Int;
	var count:Int;
	var max:Array<Float>;
	var min:Array<Float>;
	var type:String;
}

typedef TBufferView = {
	var buffer:Int;
	var byteLength:Int;
	var byteOffset:Int;
	var target:Int;
}

typedef TBuffer = {
	var byteLength:Int;
	var uri:String;
}

typedef TMesh = {
	var name:String;
	var primitives:Array<TPrimitive>;
}

typedef TPrimitive = {
	var attributes:TAttributes;
	var indices:Int;
}

typedef TAttributes = {
	var POSITION:Null<Int>;
	var NORMAL:Null<Int>;
	var TANGENT:Null<Int>;
	var TEXCOORD_0:Null<Int>;
}
