package iron.format.gltf;

class Loader {

	public var positions:Array<Float> = null;
	public var uvs:Array<Float> = null;
	public var normals:Array<Float> = null;
	public var indices:Array<Int> = null;

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

		indices = [];
		positions = [];
		normals = [];
		uvs = [];
		var elemSize = v.byteLength / a.count;
		switch (elemSize) {
		case 1: readU8Array(format, b, a, indices);
		case 2: readU16Array(format, b, a, indices);
		default: readU32Array(format, b, a, indices);
		}
		readF32Array(format, b, format.accessors[prim.attributes.POSITION], positions);
		readF32Array(format, b, format.accessors[prim.attributes.NORMAL], normals);
		readF32Array(format, b, format.accessors[prim.attributes.TEXCOORD_0], uvs);
	}

	function readU8Array(format:TGLTF, b:kha.Blob, a:TAccessor, ar:Array<Int>) {
		var v = format.bufferViews[a.bufferView];
		var pos = v.byteOffset;
		while (pos < v.byteOffset + v.byteLength) {
			ar.push(b.readU8(pos));
			pos += 1;
		}
	}

	function readU16Array(format:TGLTF, b:kha.Blob, a:TAccessor, ar:Array<Int>) {
		var v = format.bufferViews[a.bufferView];
		var pos = v.byteOffset;
		while (pos < v.byteOffset + v.byteLength) {
			ar.push(b.readU16LE(pos));
			pos += 2;
		}
	}

	function readU32Array(format:TGLTF, b:kha.Blob, a:TAccessor, ar:Array<Int>) {
		var v = format.bufferViews[a.bufferView];
		var pos = v.byteOffset;
		while (pos < v.byteOffset + v.byteLength) {
			ar.push(b.readU32LE(pos));
			pos += 4;
		}
	}

	function readF32Array(format:TGLTF, b:kha.Blob, a:TAccessor, ar:Array<Float>) {
		var v = format.bufferViews[a.bufferView];
		var pos = v.byteOffset;
		while (pos < v.byteOffset + v.byteLength) {
			ar.push(b.readF32LE(pos));
			pos += 4;
		}
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
