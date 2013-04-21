package hxassist;

using hxassist.FileUtils;
using Alg;
using sys.FileSystem;

import hxassist.FileUtils.*;
import sys.FileSystem.*;

import neko.vm.Thread;

using Lambda;

class AutoMake {
    public static function fromFile(file:String) {
        var hxmls = getHxmls(file).list().first();
        return function(args:Array<String>) {
            var cmdLine = ['--cwd', file_name_directory(hxmls), hxmls].concat(args);
            trace(cmdLine);

            function consume() {
                var main:Thread = Thread.readMessage(true);
                var input:haxe.io.Input = Thread.readMessage(true);

                var s = "";
                while(true)
                {
                    try {
                        s += String.fromCharCode(input.readByte());
                    } catch (e:haxe.io.Eof) {
                        main.sendMessage(s);
                        break;
                    }
                }
            }

            var t1 = Thread.create(consume);
            var t2 = Thread.create(consume);
            t1.sendMessage(Thread.current());
            t2.sendMessage(Thread.current());
            var proc = new sys.io.Process('haxe', cmdLine);
            t1.sendMessage(proc.stdout);
            t2.sendMessage(proc.stderr);

            proc.exitCode();

            trace(Thread.readMessage(true));
            Thread.readMessage(true);
        }
    }

    static var getCwd = file_name_directory.compose(FileSystem.fullPath);
    static var getHxmls = upward_match_files.bind(_, ~/.*\.hxml/).compose(getCwd);
}