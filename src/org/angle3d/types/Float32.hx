package org.angle3d.types;

typedef Float32 = #if cpp cpp.Float32 #elseif hl hl.F32 #else Float #end;