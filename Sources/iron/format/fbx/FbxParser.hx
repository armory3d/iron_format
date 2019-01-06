package iron.format.fbx;

import iron.format.fbx.Library;

class FbxParser {

	public var posa:kha.arrays.Int16Array = null;
	public var nora:kha.arrays.Int16Array = null;
	public var texa:kha.arrays.Int16Array = null;
	public var inda:kha.arrays.Uint32Array = null;
	public var scalePos = 1.0;
	public var scaleTex = 1.0;
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
		
		// Pack positions to (-1, 1) range
		var hx = 0.0;
		var hy = 0.0;
		var hz = 0.0;
		for (i in 0...Std.int(res.posa.length / 3)) {
			var f = Math.abs(res.posa[i * 3]);
			if (hx < f) hx = f;
			f = Math.abs(res.posa[i * 3 + 1]);
			if (hy < f) hy = f;
			f = Math.abs(res.posa[i * 3 + 2]);
			if (hz < f) hz = f;
		}
		scalePos = Math.max(hx, Math.max(hy, hz));
		var inv = 1 / scalePos;

		// Pack into 16bit
		var verts = Std.int(res.posa.length / 3);
		posa = new kha.arrays.Int16Array(verts * 4);
		nora = new kha.arrays.Int16Array(verts * 2);
		texa = res.texa != null ? new kha.arrays.Int16Array(verts * 2) : null;
		for (i in 0...verts) {
			posa[i * 4    ] = Std.int(res.posa[i * 3    ] * 32767 * inv);
			posa[i * 4 + 1] = Std.int(res.posa[i * 3 + 1] * 32767 * inv);
			posa[i * 4 + 2] = Std.int(res.posa[i * 3 + 2] * 32767 * inv);
			posa[i * 4 + 3] = Std.int(res.nora[i * 3 + 2] * 32767);
			nora[i * 2    ] = Std.int(res.nora[i * 3    ] * 32767);
			nora[i * 2 + 1] = Std.int(res.nora[i * 3 + 1] * 32767);
			if (texa != null) {
				texa[i * 2    ] = Std.int(res.texa[i * 2    ] * 32767);
				texa[i * 2 + 1] = Std.int(res.texa[i * 2 + 1] * 32767);
			}
		}

		inda = res.inda;
		name = FbxTools.getName(geoms[current].getRoot());
		name = name.substring(0, name.length - 10); // -Geometry
		current++;
		return true;
	}
}
