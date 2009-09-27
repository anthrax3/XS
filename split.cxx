/* split.c -- split strings based on separators ($Revision: 1.1.1.1 $) */

#include "es.hxx"
#include "gc.hxx"

static bool coalesce;
static bool splitchars;
static Buffer *buffer;
static List *value;

static bool ifsvalid = false;
static char ifs[10], isifs[256];

extern void startsplit(const char *sep, bool coalescef) {
	value = NULL;
	buffer = NULL;
	coalesce = coalescef;
	splitchars = !coalesce && *sep == '\0';

	if (!ifsvalid || !streq(sep, ifs)) {
		int c;
		if (strlen(sep) + 1 < sizeof ifs) {
			strcpy(ifs, sep);
			ifsvalid = true;
		} else
			ifsvalid = false;
		memzero(isifs, sizeof isifs);
		for (isifs['\0'] = true; (c = (*(unsigned const char *)sep)) != '\0'; sep++)
			isifs[c] = true;
	}
}

static void skipifs(unsigned char*& s, Buffer*& buf, unsigned char * inend) {
	assert(coalesce);
	while (s < inend) {
		int c = *s++;
		if (!isifs[c]) {
			buf = bufputc(openbuffer(0), c);
			return;
		}
	}
	buf = NULL; /* Tell endsplit not to touch buffer */
}

template <bool coalesce>
static inline void newbuf(unsigned char*& s, Buffer*& buf, unsigned char *inend) {
	if (coalesce) skipifs(s, buf, inend);
	else buf = openbuffer(0);
}

template <bool coalesce>
static inline void handleifs(unsigned char*& s, Buffer*& buf, unsigned char *inend) {
	Term *term = mkstr(sealcountedbuffer(buf));
	value = mklist(term, value);
	newbuf<coalesce>(s, buf, inend);
}

/* Doesn't handle splitchars case, only coalesce + normal */
template <bool coalesce>
static void runsplit(unsigned char*& s, Buffer*& buf, unsigned char * inend) {
	if (buf == NULL) newbuf<coalesce>(s, buf, inend);
	while (s < inend) {
		int c = *s++;
		if (isifs[c]) handleifs<coalesce>(s, buf, inend);
		else buf = bufputc(buf, c);
	}
}

extern void splitstring(const char *in, size_t len, bool endword) {
	Buffer *buf = buffer;
	unsigned char *s = (unsigned char *) in, *const inend = s + len;

	if (splitchars) {
		assert(buf == NULL);
		while (s < inend) {
			Term *term = mkstr(gcndup((char *) s++, 1));
			value = mklist(term, value);
		}
		
		return;
	} 
	else if (coalesce) runsplit<true>(s, buf, inend);
	else runsplit<false>(s, buf, inend);

	if (endword && buf != NULL) {
		Term *term = mkstr(sealcountedbuffer(buf));
		value = mklist(term, value);
		buf = NULL;
	}
	buffer = buf;
	
}

extern List* endsplit(void) {
	if (buffer != NULL) {
		Term* term = mkstr(sealcountedbuffer(buffer));
		value = mklist(term, value);
		buffer = NULL;
	}
	List* result = reverse(value);
	value = NULL;
	return result;
}

extern List* fsplit(const char *sep, List* list, bool coalesce) {
	startsplit(sep, coalesce);
	for (; list; list = list->next) {
		const char* s = getstr(list->term);
		splitstring(s, strlen(s), true);
	}
	return endsplit();
}
