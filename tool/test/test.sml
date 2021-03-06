fun exec (program: string) (args: string list) : Basis.Os.Process.status =
    Basis.Os.Process.system (program ^ " " ^ Ponyo.String.join(args, " "));

structure Main =
struct
    local
        structure FileSystem = Ponyo.Os.FileSystem
        structure File = FileSystem.File
        structure Path = Ponyo.Os.Path

        structure String = Ponyo.String
        structure Format = Ponyo.Format
    in

    fun findFiles (currentPath: string) (foundFiles: string list) : string list =
        if String.hasSuffix (currentPath, "_Test.sml")
            then currentPath :: foundFiles
        else foundFiles

    fun testFiles (directory) : string list =
        FileSystem.walkWith directory findFiles []

    fun generateUses (files: string list) : string =
        String.join (map (fn (file: string) => Format.sprintf "use \"%\";\n" [file]) files, "")

    fun generateTests (files: string list) : string =
        let
            fun generateRun (file: string) : string =
                Format.sprintf "test \"%\" (%.run ())" [Path.filename file, Path.filename file]
        in
            String.join (map generateRun files, ",\n")
        end

    fun generateFile (files: string list) : string =
        (generateUses files) ^
        Format.sprintf
        ("local structure Format = Ponyo.Format; val test = Ponyo.Test.test in\n" ^
        "fun main () =\n" ^
        "    let\n" ^
        "        val _ = Format.println [\"Beginning tests.\"]\n" ^
        "        val tests = test \"All\" [%] handle e => (PolyML.print (e); false)\n" ^
        "    in\n" ^
        "        if tests then Format.println [\"All tests passed!\"]\n" ^
        "        else (Format.println [\"Tests failed.\"]; Basis.Os.Process.exit (Basis.Os.Process.failure); ())\n" ^
        "    end\n" ^
        "end") [generateTests files]

    fun writePage (path: string) (page: string) : unit =
        let
            val pageDir = Path.directory (path)
        in
            if FileSystem.exists (pageDir)
                then ()
            else FileSystem.makeDirectory (pageDir);
            File.writeTo (path, page)
        end

    fun main () =
        let
            val tests = testFiles ("test")
            val testFile = generateFile (tests)
            val testFileName = "/tmp/test.sml"
        in
            writePage testFileName testFile;
            exec "ponyo-make" [testFileName, "-o", "/tmp/test"];
            exec "/tmp/test" [];
            ()
        end

    end
end

val main = Main.main
