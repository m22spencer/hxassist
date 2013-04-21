package hxassist;

using hxassist.FileUtils;
using Alg;
using sys.FileSystem;

import hxassist.FileUtils.*;
import sys.FileSystem.*;

using Lambda;

class AutoMake {
    public static function fromFile(file:String) {
        var hxmls = getHxmls(file).list().first();
        return function(args:Array<String>) {
            var cmdLine = ['--cwd', file_name_directory(hxmls), hxmls].concat(args);
            trace(cmdLine);
            var proc = new sys.io.Process('haxe', cmdLine);
            proc.exitCode();
            Sys.println(proc.stdout.readAll().toString());
            Sys.println(proc.stderr.readAll().toString());
        }
    }

    static var getCwd = file_name_directory.compose(FileSystem.fullPath);
    static var getHxmls = upward_match_files.bind(_, ~/.*\.hxml/).compose(getCwd);
}