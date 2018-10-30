package iron.format.obj;

class ObjParser {

	public var posa:kha.arrays.Float32Array = null;
	public var nora:kha.arrays.Float32Array = null;
	public var texa:kha.arrays.Float32Array = null;
	public var inda:kha.arrays.Uint32Array = null;
	public var name = "";

	public var hasNext = false; // File contains multiple objects
	public var pos = 0;
	
	static var lastName = "";
	static var vindOff = 0;
	static var tindOff = 0;
	static var nindOff = 0;

	public function new(blob:kha.Blob, startPos = 0) {
		pos = startPos;

		var vertexIndices:Array<Int> = [];
		var uvIndices:Array<Int> = [];
		var normalIndices:Array<Int> = [];

		var tempPositions:Array<Float> = [];
		var tempUVs:Array<Float> = [];
		var tempNormals:Array<Float> = [];

		name = lastName;

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
			else if (words[0] == "o") {
				if (words.length > 1) {
					lastName = words[1];
					if (name == "") name = lastName;
				}
				if (startPos > 0 || hasNext) { // Pass through the first "o"
					hasNext = true;
					break;
				}
				hasNext = true;
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

		posa = new kha.arrays.Float32Array(vertexIndices.length * 3);
		inda = new kha.arrays.Uint32Array(vertexIndices.length);
		for (i in 0...vertexIndices.length) {
			posa[i * 3] = tempPositions[(vertexIndices[i] - 1) * 3];
			posa[i * 3 + 1] = -tempPositions[(vertexIndices[i] - 1) * 3 + 2];
			posa[i * 3 + 2] = tempPositions[(vertexIndices[i] - 1) * 3 + 1];
			inda[i] = i;
		}

		if (normalIndices.length > 0) {
			nora = new kha.arrays.Float32Array(normalIndices.length * 3);
			for (i in 0...vertexIndices.length) {
				nora[i * 3] = tempNormals[(normalIndices[i] - 1) * 3];
				nora[i * 3 + 1] = -tempNormals[(normalIndices[i] - 1) * 3 + 2];
				nora[i * 3 + 2] = tempNormals[(normalIndices[i] - 1) * 3 + 1];
			}
		}
		else {
			// Calc normals
			nora = new kha.arrays.Float32Array(inda.length * 3);
			var va = new iron.math.Vec4();
			var vb = new iron.math.Vec4();
			var vc = new iron.math.Vec4();
			var cb = new iron.math.Vec4();
			var ab = new iron.math.Vec4();
			for (i in 0...Std.int(inda.length / 3)) {
				var i1 = inda[i * 3];
				var i2 = inda[i * 3 + 1];
				var i3 = inda[i * 3 + 2];
				va.set(posa[i1 * 3], posa[i1 * 3 + 1], posa[i1 * 3 + 2]);
				vb.set(posa[i2 * 3], posa[i2 * 3 + 1], posa[i2 * 3 + 2]);
				vc.set(posa[i3 * 3], posa[i3 * 3 + 1], posa[i3 * 3 + 2]);
				cb.subvecs(vc, vb);
				ab.subvecs(va, vb);
				cb.cross(ab);
				cb.normalize();

				nora[i1 * 3] = cb.x; nora[i1 * 3 + 1] = cb.y; nora[i1 * 3 + 2] = cb.z;
				nora[i2 * 3] = cb.x; nora[i2 * 3 + 1] = cb.y; nora[i2 * 3 + 2] = cb.z;
				nora[i3 * 3] = cb.x; nora[i3 * 3 + 1] = cb.y; nora[i3 * 3 + 2] = cb.z;
			}
		}

		if (uvIndices.length > 0) {
			texa = new kha.arrays.Float32Array(uvIndices.length * 2);
			for (i in 0...vertexIndices.length) {
				texa[i * 2] = tempUVs[(uvIndices[i] - 1) * 2];
				texa[i * 2 + 1] = 1.0 - tempUVs[(uvIndices[i] - 1) * 2 + 1];
			}
		}
	}
}
