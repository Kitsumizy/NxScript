package nx.common;

import haxe.extern.EitherType;


typedef NxException = NxError;

typedef SourceContentOrPath = EitherType<String, NxRawSource>;