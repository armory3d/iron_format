package iron.format.obj;

import iron.data.SceneFormat;

class ObjParser {

	public var posa:TFloat32Array = null;
	public var nora:TFloat32Array = null;
	public var texa:TFloat32Array = null;
	public var inda:TUint32Array = null;

	public function new(blob:kha.Blob) {

		var vertexIndices:Array<Int> = [];
		var uvIndices:Array<Int> = [];
		var normalIndices:Array<Int> = [];

		var tempPositions:Array<Float> = [];
		var tempUVs:Array<Float> = [];
		var tempNormals:Array<Float> = [];

		var pos = 0;
		while (true) {

			if (pos >= blob.length) break;

			var line = "";

			while (true) {
				var c = String.fromCharCode(blob.readU8(pos));
				pos++;
				if (c == "\n") break;
				if (pos >= blob.length) break;
				line += c;
			}

			var words:Array<String> = line.split(" ");

			if (words[0] == "v") {
				tempPositions.push(Std.parseFloat(words[1]));
				tempPositions.push(Std.parseFloat(words[2]));
				tempPositions.push(Std.parseFloat(words[3]));
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
				var sec1:Array<String> = words[1].split("/");
				var sec2:Array<String> = words[2].split("/");
				var sec3:Array<String> = words[3].split("/");
				var sec4:Array<String> = words.length > 4 ? words[4].split("/") : null;

				var vi0 = Std.int(Std.parseFloat(sec1[0]));
				var vi1 = Std.int(Std.parseFloat(sec2[0]));
				var vi2 = Std.int(Std.parseFloat(sec3[0]));
				vertexIndices.push(vi0);
				vertexIndices.push(vi1);
				vertexIndices.push(vi2);
				if (words.length > 4) {
					vertexIndices.push(vi2);
					vertexIndices.push(Std.int(Std.parseFloat(sec4[0])));
					vertexIndices.push(vi0);
				}

				if (tempUVs.length > 0) {
					var vuv0 = Std.int(Std.parseFloat(sec1[1]));
					var vuv1 = Std.int(Std.parseFloat(sec2[1]));
					var vuv2 = Std.int(Std.parseFloat(sec3[1]));
					uvIndices.push(vuv0);
					uvIndices.push(vuv1);
					uvIndices.push(vuv2);
					if (words.length > 4) {
						uvIndices.push(vuv2);
						uvIndices.push(Std.int(Std.parseFloat(sec4[1])));
						uvIndices.push(vuv0);
					}
				}
				
				if (tempNormals.length > 0) {
					var vn0 = Std.int(Std.parseFloat(sec1[2]));
					var vn1 = Std.int(Std.parseFloat(sec2[2]));
					var vn2 = Std.int(Std.parseFloat(sec3[2]));
					normalIndices.push(vn0);
					normalIndices.push(vn1);
					normalIndices.push(vn2);
					if (words.length > 4) {
						normalIndices.push(vn2);
						normalIndices.push(Std.int(Std.parseFloat(sec4[2])));
						normalIndices.push(vn0);
					}
				}
			}
		}

		posa = new TFloat32Array(vertexIndices.length * 3);
		inda = new TUint32Array(vertexIndices.length);
		for (i in 0...vertexIndices.length) {
			posa[i * 3] = tempPositions[(vertexIndices[i] - 1) * 3];
			posa[i * 3 + 1] = -tempPositions[(vertexIndices[i] - 1) * 3 + 2];
			posa[i * 3 + 2] = tempPositions[(vertexIndices[i] - 1) * 3 + 1];
			inda[i] = i;
		}

		nora = new TFloat32Array(normalIndices.length * 3);
		if (normalIndices.length > 0) {
			for (i in 0...vertexIndices.length) {
				nora[i * 3] = tempNormals[(normalIndices[i] - 1) * 3];
				nora[i * 3 + 1] = -tempNormals[(normalIndices[i] - 1) * 3 + 2];
				nora[i * 3 + 2] = tempNormals[(normalIndices[i] - 1) * 3 + 1];
			}
		}
		else {
			// Calc normals
			var va = new iron.math.Vec4();
			var vb = new iron.math.Vec4();
			var vc = new iron.math.Vec4();
			var cb = new iron.math.Vec4();
			var ab = new iron.math.Vec4();
			for (i in 0...Std.int(vertexIndices.length / 3)) {
				va.set(posa[i * 3], posa[i * 3 + 1], posa[i * 3 + 2]);
				vb.set(posa[(i + 1) * 3], posa[(i + 1) * 3 + 1], posa[(i + 1) * 3 + 2]);
				vc.set(posa[(i + 2) * 3], posa[(i + 2) * 3 + 1], posa[(i + 2) * 3 + 2]);
				cb.subvecs(vc, vb);
				ab.subvecs(va, vb);
				cb.cross(ab);
				cb.normalize();
				cb = ab;
				nora[i * 9 + 0] = cb.x; nora[i * 9 + 1] = cb.y; nora[i * 9 + 2] = cb.z;
				nora[i * 9 + 3] = cb.x; nora[i * 9 + 4] = cb.y; nora[i * 9 + 5] = cb.z;
				nora[i * 9 + 6] = cb.x; nora[i * 9 + 7] = cb.y; nora[i * 9 + 8] = cb.z;
			}
		}

		if (uvIndices.length > 0) {
			texa = new TFloat32Array(uvIndices.length * 2);
			for (i in 0...vertexIndices.length) {
				texa[i * 2] = tempUVs[(uvIndices[i] - 1) * 2];
				texa[i * 2 + 1] = 1.0 - tempUVs[(uvIndices[i] - 1) * 2 + 1];
			}
		}
	}
}
