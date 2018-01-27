package iron.format.obj;

class Loader {

	public var positions:Array<Float> = null;
	public var uvs:Array<Float> = null;
	public var normals:Array<Float> = null;
	public var indices:Array<Int>;

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

				var vi0 = Std.int(Std.parseFloat(sec1[0]));
				var vi1 = Std.int(Std.parseFloat(sec2[0]));
				var vi2 = Std.int(Std.parseFloat(sec3[0]));
				vertexIndices.push(vi0);
				vertexIndices.push(vi1);
				vertexIndices.push(vi2);

				var vuv0 = Std.int(Std.parseFloat(sec1[1]));
				var vuv1 = Std.int(Std.parseFloat(sec2[1]));
				var vuv2 = Std.int(Std.parseFloat(sec3[1]));
				uvIndices.push(vuv0);
				uvIndices.push(vuv1);
				uvIndices.push(vuv2);
				
				var vn0 = Std.int(Std.parseFloat(sec1[2]));
				var vn1 = Std.int(Std.parseFloat(sec2[2]));
				var vn2 = Std.int(Std.parseFloat(sec3[2]));
				normalIndices.push(vn0);
				normalIndices.push(vn1);
				normalIndices.push(vn2);

				if (words.length > 4) {
					var sec4:Array<String> = words[4].split("/");

					vertexIndices.push(vi2);
					vertexIndices.push(Std.int(Std.parseFloat(sec4[0])));
					vertexIndices.push(vi0);

					uvIndices.push(vuv2);
					uvIndices.push(Std.int(Std.parseFloat(sec4[1])));
					uvIndices.push(vuv0);

					normalIndices.push(vn2);
					normalIndices.push(Std.int(Std.parseFloat(sec4[2])));
					normalIndices.push(vn0);
				}
			}
		}

		// UVs not found
		if (tempUVs.length == 0) return;

		positions = [];
		uvs = [];
		normals = [];
		indices = [];

		for (i in 0...vertexIndices.length) {
			positions.push(tempPositions[(vertexIndices[i] - 1) * 3]);
			positions.push(tempPositions[(vertexIndices[i] - 1) * 3 + 1]);
			positions.push(tempPositions[(vertexIndices[i] - 1) * 3 + 2]);
			uvs.push(tempUVs[(uvIndices[i] - 1) * 2]);
			uvs.push(1.0 - tempUVs[(uvIndices[i] - 1) * 2 + 1]);
			normals.push(tempNormals[(normalIndices[i] - 1) * 3]);
			normals.push(tempNormals[(normalIndices[i] - 1) * 3 + 1]);
			normals.push(tempNormals[(normalIndices[i] - 1) * 3 + 2]);
			indices.push(i);
		}
	}
}
