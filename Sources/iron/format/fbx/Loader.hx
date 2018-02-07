package iron.format.fbx;

import iron.format.fbx.Library;

class Loader {

	public var positions:Array<Float> = null;
	public var normals:Array<Float> = null;
	public var uvs:Array<Float> = null;
	public var indices:Array<Int>;

	public function new(blob:kha.Blob) {
		var magic = "Kaydara FBX Binary\x20\x20\x00\x1a\x00";
		var s = '';
		for (i in 0...magic.length) s += String.fromCharCode(blob.readU8(i));
		var bin = s == magic;

		var fbx = bin ? BinaryParser.parse(blob) : Parser.parse(blob.toString());
		var lib = new Library();
		lib.load(fbx);

		var g = lib.getFirstGeometry();
		indices = [];
		positions = [];
		normals = [];
		uvs = [];
		g.getBuffers(positions, normals, uvs, indices, bin);
	}
}
