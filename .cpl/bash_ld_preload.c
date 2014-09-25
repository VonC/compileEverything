#include <sys/types.h>
#include <stdlib.h>
#include <string.h>

static void __attribute__ ((constructor)) strip_env(void);
extern char **environ;

static void strip_env()
{
	char *p,*c;
	int i = 0;
	for (p = environ[i]; p!=NULL;i++ ) {
		c = strstr(p,"=() {");
		if (c != NULL) {
			*(c+2) = '\0';
		}
		p = environ[i];
	}
}
