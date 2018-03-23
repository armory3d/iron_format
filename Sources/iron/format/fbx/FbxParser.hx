package iron.format.fbx;

import iron.format.fbx.Library;

class FbxParser {

	public var posa:kha.arrays.Float32Array = null;
	public var nora:kha.arrays.Float32Array = null;
	public var texa:kha.arrays.Float32Array = null;
	public var inda:kha.arrays.Uint32Array = null;

	public function new(blob:kha.Blob) {
		var magic = "Kaydara FBX Binary\x20\x20\x00\x1a\x00";
		var s = '';
		for (i in 0...magic.length) s += String.fromCharCode(blob.readU8(i));
		var bin = s == magic;

		var fbx = bin ? BinaryParser.parse(blob) : Parser.parse(blob.toString());
		var lib = new Library();
		lib.load(fbx);

		var g = lib.getFirstGeometry();
		var res = g.getBuffers(bin);
		posa = res.posa;
		nora = res.nora;
		texa = res.texa;
		inda = res.inda;
	}
}
