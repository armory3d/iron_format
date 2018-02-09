package iron.format.gltf;

import iron.data.SceneFormat;

class GltfParser {

	public var posa:TFloat32Array = null;
	public var nora:TFloat32Array = null;
	public var texa:TFloat32Array = null;
	public var inda:TUint32Array = null;

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
		posa = readF32Array(format, b, format.accessors[prim.attributes.POSITION]);
		nora = readF32Array(format, b, format.accessors[prim.attributes.NORMAL]);
		if (prim.attributes.TEXCOORD_0 != null) texa = readF32Array(format, b, format.accessors[prim.attributes.TEXCOORD_0]);
	}

	function readU8Array(format:TGLTF, b:kha.Blob, a:TAccessor):TUint32Array {
		var v = format.bufferViews[a.bufferView];
		var ar = new TUint32Array(v.byteLength);
		var pos = v.byteOffset;
		var i = 0;
		while (pos < v.byteOffset + v.byteLength) {
			ar[i] = b.readU8(pos);
			pos += 1;
			i++;
		}
		return ar;
	}

	function readU16Array(format:TGLTF, b:kha.Blob, a:TAccessor):TUint32Array {
		var v = format.bufferViews[a.bufferView];
		var ar = new TUint32Array(Std.int(v.byteLength / 2));
		var pos = v.byteOffset;
		var i = 0;
		while (pos < v.byteOffset + v.byteLength) {
			ar[i] = b.readU16LE(pos);
			pos += 2;
			i++;
		}
		return ar;
	}

	function readU32Array(format:TGLTF, b:kha.Blob, a:TAccessor):TUint32Array {
		var v = format.bufferViews[a.bufferView];
		var ar = new TUint32Array(Std.int(v.byteLength / 4));
		var pos = v.byteOffset;
		var i = 0;
		while (pos < v.byteOffset + v.byteLength) {
			ar[i] = b.readU32LE(pos);
			pos += 4;
			i++;
		}
		return ar;
	}

	function readF32Array(format:TGLTF, b:kha.Blob, a:TAccessor):TFloat32Array {
		var v = format.bufferViews[a.bufferView];
		var ar = new TFloat32Array(Std.int(v.byteLength / 4));
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
	var POSITION:Int;
	var NORMAL:Int;
	var TANGENT:Int;
	var TEXCOORD_0:Int;
}
