package hxassist;

import haxe.ds.Option;

using hxassist.FileUtils;
using sys.io.File;
using sys.FileSystem;

class VFS {
    var tempDir:String;
    var tempCache:Map<String,String>;
    var classpaths:Array<String>;
    public function new(tempDir:String) {
        this.tempDir = tempDir.sanitize();
        tempCache = new Map();
        if (!tempDir.file_represents_dir()) throw 'VFS expects a temp path like: path/to/file/';
        classpaths = [];
    }

    public function addClasspath(classpath:String) {
        classpaths.push(classpath.sanitize());
    }

    public function writeToFileSystem() {
        for (file in tempCache.keys()) {
            var contents = tempCache.get(file);
            file.saveContent(tempCache.get(file));
        }
    }

    public function modify(file:String, fn:Option<String>->Option<String>) {
        var current = if (file.exists()) Some(file.getContent()); else None;
        switch (fn(current)) {
        case Some(v): tempCache.set(toTempPath(file), v);
        default: 
        }
    }

    function toTempPath(file:String) {
        var file = file.sanitize();
        for (c in classpaths) {
            if (file.file_within_path(c)) {
                var temp = tempDir + (file.file_relative_to_path(c));
                trace('shadowing $file with $temp');
                return temp;
            }
        }
        
        throw 'Could not convert $file to a temp path usign $classpaths!';
    }
}