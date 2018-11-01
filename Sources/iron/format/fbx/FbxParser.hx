package iron.format.fbx;

import iron.format.fbx.Library;

class FbxParser {

	public var posa:kha.arrays.Float32Array = null;
	public var nora:kha.arrays.Float32Array = null;
	public var texa:kha.arrays.Float32Array = null;
	public var inda:kha.arrays.Uint32Array = null;
	public var name = "";
	
	var geoms:Array<Geometry>;
	var current = 0;
	var binary = true;

	public function new(blob:kha.Blob) {
		var magic = "Kaydara FBX Binary\x20\x20\x00\x1a\x00";
		var s = '';
		for (i in 0...magic.length) s += String.fromCharCode(blob.readU8(i));
		binary = s == magic;

		var fbx = binary ? BinaryParser.parse(blob) : Parser.parse(blob.toString());
		var lib = new Library();
		try { lib.load(fbx); }
		catch(e:Dynamic) { trace(e); }

		geoms = lib.getAllGeometries();
		next();
	}

	public function next():Bool {
		if (current >= geoms.length) return false;
		var res = geoms[current].getBuffers(binary);
		posa = res.posa;
		nora = res.nora;
		texa = res.texa;
		inda = res.inda;
		name = FbxTools.getName(geoms[current].getRoot());
		name = name.substring(0, name.length - 10); // -Geometry
		current++;
		return true;
	}
}
