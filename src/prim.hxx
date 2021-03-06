/* prim.hxx -- definitions for xs primitives */
#include <string>

#define	PRIM(name)	static const List* CONCAT(prim_,name)( \
				List* list, \
				Binding* binding, \
				int evalflags \
			)
#define	X(name)		primdict[STRING(name)] = CONCAT(prim_,name)

typedef const List* (*Prim)(List*, Binding*, int);
#include <tr1/unordered_map>
typedef std::tr1::unordered_map<std::string, Prim> Prim_dict;

extern void initprims_controlflow(Prim_dict& primdict);	/* prim-ctl.cxx */
extern void initprims_io(Prim_dict& primdict);		/* prim-io.cxx */
extern void initprims_etc(Prim_dict& primdict);		/* prim-etc.cxx */
extern void initprims_sys(Prim_dict& primdict);		/* prim-sys.cxx */
extern void initprims_rel(Prim_dict& primdict);		/* prim-rel.cxx */
extern void initprims_proc(Prim_dict& primdict);	/* proc.cxx */
extern void initprims_access(Prim_dict& primdict);	/* access.cxx */

