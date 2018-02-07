package iron.format.fbx;

import iron.format.fbx.Library;

class Loader {

	public var positions:Array<Float> = null;
	public var normals:Array<Float> = null;
	public var uvs:Array<Float> = null;
	public var indices:Array<Int>;

	public function new(blob:kha.Blob) {
		var fbx = Parser.parse(blob.toString());
		var lib = new Library();
		lib.load(fbx);
		var g = lib.getFirstGeometry();
		indices = [];
		positions = [];
		normals = [];
		uvs = [];
		g.getBuffers(positions, normals, uvs, indices);		
	}
}
