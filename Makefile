VIMBALL = syntax-export.vba

FILES = \
	plugin/now/syntax-export-to-html.xsl \
	plugin/now/syntax-export-to-nml-fragment.xsl \
	plugin/now/syntax-export.rnc \
	plugin/now/syntax-export.rng \
	plugin/now/syntax-export.vim

.PHONY: build install package

build: $(VIMBALL)

install: build
	ex -N --cmd 'set eventignore=all' -c 'so %' -c 'quit!' $(VIMBALL)

package: $(VIMBALL).gz

$(VIMBALL): Manifest $(FILES)
	ex -N -c '%MkVimball! $@ .' -c 'quit!' $<

%.gz: %
	gzip -c $< > $@

Manifest: Makefile
	for f in $(FILES); do echo $$f; done > $@
