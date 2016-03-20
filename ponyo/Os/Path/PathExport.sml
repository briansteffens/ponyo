structure PathExport =
struct
    local structure String = StringExport in

    fun join (paths: string list) =
        case paths of
            [] => ""
          | [path] => path
          | path :: paths =>
             String.join ([String.stripRight (path, "/"),
                           String.stripLeft (join paths, "/")], "/")
    end
end
