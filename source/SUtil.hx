package;

#if android
import android.os.Environment;
import android.widget.Toast;
#end
import haxe.CallStack;
import haxe.io.Path;
import lime.system.System as LimeSystem;
import lime.utils.Assets as LimeAssets;
import openfl.Lib;
import openfl.events.UncaughtErrorEvent;
import openfl.system.System as OpenFlSystem;
import openfl.utils.Assets as OpenFlAssets;
import lime.app.Application;
#if sys
import sys.FileSystem;
import sys.io.File;
#else
import haxe.Log;
#end

using StringTools;

enum StorageType
{
	DATA;
	EXTERNAL_DATA;
}

/**
 * ...
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class SUtil
{
	/**
	 * This returns the external storage path that the game will use by the type.
	 */
	public static function getStorageDirectory():String
	{
		#if android
		return Environment.getExternalStorageDirectory() + '/' + '.' + Application.current.meta.get('file') + '/';
		#else
		return '';
		#end
	}

	/**
	 * A simple function that checks for game files/folders.
	 */
	public static function checkFiles():Void
	{
		#if mobile
		for (file in OpenFlAssets.list().filter(folder -> folder.contains('assets/videos')))
		{
			if (file.endsWith('.mp4'))
			{
				@:privateAccess
				for (key => library in LimeAssets.libraryPaths)
				{
					var shit:String = file.replace('assets/', '');
					if (shit.replace(shit.substring(shit.indexOf('/', 0), shit.length), '') == key)
						SUtil.copyContent('$key:$file', SUtil.getStorageDirectory() + file);
					else
						SUtil.copyContent(file, SUtil.getStorageDirectory() + file);
				}
			}
		}

		OpenFlSystem.gc(); // clean le memory.
		#end
	}

	/**
	 * Uncaught error handler, original made by: Sqirra-RNG and YoshiCrafter29
	 */
	public static function uncaughtErrorHandler():Void
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
		Lib.application.onExit.add(function(exitCode:Int)
		{
			if (Lib.current.loaderInfo.uncaughtErrorEvents.hasEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR))
				Lib.current.loaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onError);
		});
	}

	private static function onError(e:UncaughtErrorEvent):Void
	{
		var stack:Array<String> = [];
		stack.push(e.error);

		for (stackItem in CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case CFunction:
					stack.push('Non-Haxe (C) Function');
				case Module(m):
					stack.push('Module ($m)');
				case FilePos(s, file, line, column):
					stack.push('$file (line $line)');
				case Method(classname, method):
					stack.push('$classname (method $method)');
				case LocalFunction(name):
					stack.push('Local Function ($name)');
			}
		}

		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		final msg:String = stack.join('\n');

		#if sys
		try
		{
			if (!FileSystem.exists(SUtil.getStorageDirectory() + 'crash'))
				FileSystem.createDirectory(SUtil.getStorageDirectory() + 'crash');

			File.saveContent(SUtil.getStorageDirectory()
				+ 'crash/'
				+ 'DDTO_'
				+ Date.now().toString().replace(' ', '-').replace(':', "'")
				+ '.txt',
				msg + '\n');
		}
		catch (e:Dynamic)
		{
			#if android
			Toast.makeText("Error!\nClouldn't save the crash dump because:\n" + e, Toast.LENGTH_LONG);
			#else
			println("Error!\nClouldn't save the crash dump because:\n" + e);
			#end
		}
		#end

		println(msg);
		Lib.application.window.alert(msg, 'Error!');
		LimeSystem.exit(1);
	}

	/**
	 * This is mostly a fork of https://github.com/openfl/hxp/blob/master/src/hxp/System.hx#L595
	 */
	public static function mkDirs(directory:String):Void
	{
		var total:String = '';

		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');

		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				if (!FileSystem.exists(total))
					FileSystem.createDirectory(total);
			}
		}
	}

	#if sys
	public static function saveContent(fileName:String = 'file', fileExtension:String = '.json',
			fileData:String = 'you forgot to add something in your code lol'):Void
	{
		try
		{
			if (!FileSystem.exists(SUtil.getStorageDirectory() + 'saves'))
				FileSystem.createDirectory(SUtil.getStorageDirectory() + 'saves');

			File.saveContent(SUtil.getStorageDirectory() + 'saves/' + fileName + fileExtension, fileData);
			#if android
			Toast.makeText("File Saved Successfully!", Toast.LENGTH_LONG);
			#end
		}
		catch (e:Dynamic)
		{
			#if android
			Toast.makeText("Error!\nClouldn't save the file because:\n" + e, Toast.LENGTH_LONG);
			#else
			println("Error!\nClouldn't save the file because:\n" + e);
			#end
		}
	}

	public static function copyContent(copyPath:String, savePath:String):Void
	{
		try
		{
			if (!FileSystem.exists(savePath) && OpenFlAssets.exists(copyPath))
			{
				if (!FileSystem.exists(Path.directory(savePath)))
					SUtil.mkDirs(Path.directory(savePath));

				File.saveBytes(savePath, OpenFlAssets.getBytes(copyPath));
			}
		}
		catch (e:Dynamic)
		{
			#if android
			Toast.makeText("Error!\nClouldn't copy the file because:\n" + e, Toast.LENGTH_LONG);
			#else
			println("Error!\nClouldn't copy the file because:\n" + e);
			#end
		}
	}
	#end

	private static function println(msg:String):Void
	{
		#if sys
		Sys.println(msg);
		#else
		Log.trace(msg, null); // Pass null to exclude the position.
		#end
	}
}
