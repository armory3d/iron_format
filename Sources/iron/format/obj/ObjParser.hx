package iron.format.obj;

class ObjParser {

	public var posa:kha.arrays.Int16Array = null;
	public var nora:kha.arrays.Int16Array = null;
	public var texa:kha.arrays.Int16Array = null;
	public var inda:kha.arrays.Uint32Array = null;
	public var udims:Array<kha.arrays.Uint32Array> = null; // Indices split per udim tile
	public var udimsU = 1; // Number of horizontal udim tiles
	public var scalePos = 1.0;
	public var scaleTex = 1.0;
	public var name = "";

	public var hasNext = false; // File contains multiple objects
	public var pos = 0;
	
	static var vindOff = 0;
	static var tindOff = 0;
	static var nindOff = 0;

	public function new(blob:kha.Blob, startPos = 0, udim = false) {
		pos = startPos;

		var vertexIndices:Array<Int> = [];
		var uvIndices:Array<Int> = [];
		var normalIndices:Array<Int> = [];

		var tempPositions:Array<Float> = [];
		var tempUVs:Array<Float> = [];
		var tempNormals:Array<Float> = [];

		var readingFaces = false;
		var readingObject = false;

		while (true) {

			if (pos >= blob.length) break;

			var line = "";

			var i = 0;
			var c = String.fromCharCode(blob.readU8(pos));
			if (readingObject && readingFaces && (c == "v" || c == "o")) {
				hasNext = true;
				break;
			}

			while (true) {
				c = String.fromCharCode(blob.readU8(pos));
				pos++;
				i++;
				if (c == "\n" || c == "\r" || pos >= blob.length) break;
				line += c;
			}

			var words:Array<String> = line.split(" ");

			if (words[0] == "v") {
				// Some exporters put space directly after "v"
				tempPositions.push(Std.parseFloat(words[words.length - 3]));
				tempPositions.push(Std.parseFloat(words[words.length - 2]));
				tempPositions.push(Std.parseFloat(words[words.length - 1]));
			}
			else if (words[0] == "vt") {
				tempUVs.push(Std.parseFloat(words[1]));
				tempUVs.push(Std.parseFloat(words[2]));
			}
			else if (words[0] == "vn") {
				tempNormals.push(Std.parseFloat(words[1]));
				tempNormals.push(Std.parseFloat(words[2]));
				tempNormals.push(Std.parseFloat(words[3]));
			}
			else if (words[0] == "f") {
				readingFaces = true;
				var isQuad = words.length > 4 && words[4].length > 0; // Some exporters put space at the end of "f" line
				var sec0:Array<String> = words[1].split("/");
				var sec1:Array<String> = words[2].split("/");
				var sec2:Array<String> = words[3].split("/");
				var sec3:Array<String> = isQuad ? words[4].split("/") : null;

				var vi0 = Std.parseInt(sec0[0]);
				var vi1 = Std.parseInt(sec1[0]);
				var vi2 = Std.parseInt(sec2[0]);
				vertexIndices.push(vi0);
				vertexIndices.push(vi1);
				vertexIndices.push(vi2);
				if (isQuad) {
					vertexIndices.push(vi2);
					vertexIndices.push(Std.parseInt(sec3[0]));
					vertexIndices.push(vi0);
					if (words.length > 5) { // Loop
						for (i in 5...words.length) {
							if (words[i].length == 0) break;
							var seci = words[i].split("/");
							vertexIndices.push(Std.parseInt(seci[0]));
							vertexIndices.push(vertexIndices[vertexIndices.length - 2]);
							vertexIndices.push(vertexIndices[vertexIndices.length - 4]);
						}
					}
				}

				if (tempUVs.length > 0) {
					var vuv0 = Std.parseInt(sec0[1]);
					var vuv1 = Std.parseInt(sec1[1]);
					var vuv2 = Std.parseInt(sec2[1]);
					uvIndices.push(vuv0);
					uvIndices.push(vuv1);
					uvIndices.push(vuv2);
					if (isQuad) {
						uvIndices.push(vuv2);
						uvIndices.push(Std.parseInt(sec3[1]));
						uvIndices.push(vuv0);
						if (words.length > 5) { // Loop
							for (i in 5...words.length) {
								if (words[i].length == 0) break;
								var seci = words[i].split("/");
								uvIndices.push(Std.parseInt(seci[1]));
								uvIndices.push(uvIndices[uvIndices.length - 2]);
								uvIndices.push(uvIndices[uvIndices.length - 4]);
							}
						}
					}
				}
				
				if (tempNormals.length > 0) {
					var vn0 = Std.parseInt(sec0[2]);
					var vn1 = Std.parseInt(sec1[2]);
					var vn2 = Std.parseInt(sec2[2]);
					normalIndices.push(vn0);
					normalIndices.push(vn1);
					normalIndices.push(vn2);
					if (isQuad) {
						normalIndices.push(vn2);
						normalIndices.push(Std.parseInt(sec3[2]));
						normalIndices.push(vn0);
						if (words.length > 5) { // Loop
							for (i in 5...words.length) {
								if (words[i].length == 0) break;
								var seci = words[i].split("/");
								normalIndices.push(Std.parseInt(seci[2]));
								normalIndices.push(normalIndices[normalIndices.length - 2]);
								normalIndices.push(normalIndices[normalIndices.length - 4]);
							}
						}
					}
				}
			}
			// else if (words[0] == "o" || words[0] == "g") {
			else if (words[0] == "o") {
				if (!udim) readingObject = true;
				if (words.length > 1) name = words[words.length - 1];
			}
		}

		if (startPos > 0) {
			for (i in 0...vertexIndices.length) vertexIndices[i] -= vindOff;
			for (i in 0...uvIndices.length) uvIndices[i] -= tindOff;
			for (i in 0...normalIndices.length) normalIndices[i] -= nindOff;
		}
		else {
			vindOff = tindOff = nindOff = 0;
		}
		vindOff += Std.int(tempPositions.length / 3);
		tindOff += Std.int(tempUVs.length / 2);
		nindOff += Std.int(tempNormals.length / 3);

		// Pack positions to (-1, 1) range
		scalePos = 0.0;
		for (i in 0...tempPositions.length) {
			var f = Math.abs(tempPositions[i]);
			if (scalePos < f) scalePos = f;
		}
		var inv = 32767 * (1 / scalePos);

		posa = new kha.arrays.Int16Array(vertexIndices.length * 4);
		inda = new kha.arrays.Uint32Array(vertexIndices.length);
		for (i in 0...vertexIndices.length) {
			posa[i * 4    ] = Std.int( tempPositions[(vertexIndices[i] - 1) * 3    ] * inv);
			posa[i * 4 + 1] = Std.int(-tempPositions[(vertexIndices[i] - 1) * 3 + 2] * inv);
			posa[i * 4 + 2] = Std.int( tempPositions[(vertexIndices[i] - 1) * 3 + 1] * inv);
			inda[i] = i;
		}

		if (normalIndices.length > 0) {
			nora = new kha.arrays.Int16Array(normalIndices.length * 2);
			for (i in 0...vertexIndices.length) {
				nora[i * 2    ] = Std.int( tempNormals[(normalIndices[i] - 1) * 3    ] * 32767);
				nora[i * 2 + 1] = Std.int(-tempNormals[(normalIndices[i] - 1) * 3 + 2] * 32767);
				posa[i * 4 + 3] = Std.int( tempNormals[(normalIndices[i] - 1) * 3 + 1] * 32767);
			}
		}
		else {
			// Calc normals
			nora = new kha.arrays.Int16Array(inda.length * 2);
			var va = new iron.math.Vec4();
			var vb = new iron.math.Vec4();
			var vc = new iron.math.Vec4();
			var cb = new iron.math.Vec4();
			var ab = new iron.math.Vec4();
			for (i in 0...Std.int(inda.length / 3)) {
				var i1 = inda[i * 3    ];
				var i2 = inda[i * 3 + 1];
				var i3 = inda[i * 3 + 2];
				va.set(posa[i1 * 3], posa[i1 * 3 + 1], posa[i1 * 3 + 2]);
				vb.set(posa[i2 * 3], posa[i2 * 3 + 1], posa[i2 * 3 + 2]);
				vc.set(posa[i3 * 3], posa[i3 * 3 + 1], posa[i3 * 3 + 2]);
				cb.subvecs(vc, vb);
				ab.subvecs(va, vb);
				cb.cross(ab);
				cb.normalize();
				nora[i1 * 2    ] = Std.int(cb.x * 32767);
				nora[i1 * 2 + 1] = Std.int(cb.y * 32767);
				posa[i1 * 4 + 3] = Std.int(cb.z * 32767);
				nora[i2 * 2    ] = Std.int(cb.x * 32767);
				nora[i2 * 2 + 1] = Std.int(cb.y * 32767);
				posa[i2 * 4 + 3] = Std.int(cb.z * 32767);
				nora[i3 * 2    ] = Std.int(cb.x * 32767);
				nora[i3 * 2 + 1] = Std.int(cb.y * 32767);
				posa[i3 * 4 + 3] = Std.int(cb.z * 32767);
			}
		}

		if (uvIndices.length > 0) {
			if (udim) {
				// Find number of tiles
				var tilesU = 1;
				var tilesV = 1;
				for (i in 0...Std.int(tempUVs.length / 2)) {
					while (tempUVs[i * 2    ] > tilesU) tilesU++;
					while (tempUVs[i * 2 + 1] > tilesV) tilesV++;
				}

				function getTile(i1:Int, i2:Int, i3:Int):Int {
					var u1 = tempUVs[(uvIndices[i1] - 1) * 2    ];
					var v1 = tempUVs[(uvIndices[i1] - 1) * 2 + 1];
					var u2 = tempUVs[(uvIndices[i2] - 1) * 2    ];
					var v2 = tempUVs[(uvIndices[i2] - 1) * 2 + 1];
					var u3 = tempUVs[(uvIndices[i3] - 1) * 2    ];
					var v3 = tempUVs[(uvIndices[i3] - 1) * 2 + 1];
					var tileU = Std.int((u1 + u2 + u3) / 3);
					var tileV = Std.int((v1 + v2 + v3) / 3);
					return tileU + tileV * tilesU;
				}
				
				// Amount of indices pre tile
				var num = new kha.arrays.Uint32Array(tilesU * tilesV);
				for (i in 0...Std.int(inda.length / 3)) {
					var tile = getTile(inda[i * 3], inda[i * 3 + 1], inda[i * 3 + 2]);
					num[tile] += 3;
				}

				// Split indices per tile
				udims = [];
				udimsU = tilesU;
				for (i in 0...tilesU * tilesV) { udims.push(new kha.arrays.Uint32Array(num[i])); num[i] = 0; }

				for (i in 0...Std.int(inda.length / 3)) {
					var i1 = inda[i * 3    ];
					var i2 = inda[i * 3 + 1];
					var i3 = inda[i * 3 + 2];
					var tile = getTile(i1, i2, i3);
					udims[tile][num[tile]++] = i1;
					udims[tile][num[tile]++] = i2;
					udims[tile][num[tile]++] = i3;
				}

				// Normalize uvs to 0-1 range
				var uvtiles = new kha.arrays.Int16Array(tempUVs.length);
				for (i in 0...Std.int(inda.length / 3)) { // TODO: merge loops
					var i1 = inda[i * 3    ];
					var i2 = inda[i * 3 + 1];
					var i3 = inda[i * 3 + 2];
					var tile = getTile(i1, i2, i3);
					var tileU = tile % tilesU;
					var tileV = Std.int(tile / tilesU);
					uvtiles[(uvIndices[i1] - 1) * 2    ] = tileU;
					uvtiles[(uvIndices[i1] - 1) * 2 + 1] = tileV;
					uvtiles[(uvIndices[i2] - 1) * 2    ] = tileU;
					uvtiles[(uvIndices[i2] - 1) * 2 + 1] = tileV;
					uvtiles[(uvIndices[i3] - 1) * 2    ] = tileU;
					uvtiles[(uvIndices[i3] - 1) * 2 + 1] = tileV;
				}
				for (i in 0...uvtiles.length) tempUVs[i] -= uvtiles[i];
			}

			texa = new kha.arrays.Int16Array(uvIndices.length * 2);
			for (i in 0...vertexIndices.length) {
				texa[i * 2    ] = Std.int(       tempUVs[(uvIndices[i] - 1) * 2    ]  * 32767);
				texa[i * 2 + 1] = Std.int((1.0 - tempUVs[(uvIndices[i] - 1) * 2 + 1]) * 32767);
			}
		}
	}
}
