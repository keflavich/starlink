<!DOCTYPE programcode public "-//Starlink//DTD DSSSL Source Code 0.2//EN" [
<!entity sldocs.dsl		system "sldocs.dsl">
<!entity slmisc.dsl		system "slmisc.dsl">
<!entity slsect.dsl		system "slsect.dsl">
<!entity slroutines.dsl		system "slroutines.dsl">
<!entity slhtml.dsl		system "slhtml.dsl">
<!entity slnavig.dsl		system "slnavig.dsl">
<!entity sltables.dsl		system "sltables.dsl">
<!entity sllinks.dsl		system "sllinks.dsl">

<!entity slparams.dsl		system "sl-html-parameters">

<!entity lib.dsl		system "../lib/sllib.dsl" subdoc>
<!entity common.dsl		system "../common/slcommon.dsl" subdoc>
<!entity maths.dsl		system "slmaths.dsl" subdoc>
<!entity slback.dsl		system "slback.dsl" subdoc>
]>

<!-- $Id$ -->

<docblock>
<title>Starlink to HTML stylesheet
<description>
<p>This is the DSSSL stylesheet for converting the Starlink DTD to HTML.

<p>Requires Jade, for the non-standard functions.  Lots of stuff learned from 
Mark Burton's dbtohtml.dsl style file, and Norm Walsh's DocBook DSSSL
stylesheets. 

<authorlist>
<author id=ng affiliation='Glasgow'>Norman Gray

<copyright>Copyright 1999, Particle Physics and Astronomy Research Council
<history>
<change author=ng date='09-FEB-1999'>Released a version 0.1 to the other
Starlink programmers.
</history>

<codereference doc="lib.dsl" id="code.lib">
<title>Library code
<description>
<p>Some of this library code is from the standard, some from Norm
Walsh's stylesheet, other parts from me

<codereference doc="common.dsl" id="code.common">
<title>Common code
<description>
<p>Code which is common to both the HTML and print stylesheets.

<codereference doc="maths.dsl" docid="code.maths.img" id="code.maths">
<title>Maths processing
<description>
Code to process the various maths elements.

<codereference doc="slback.dsl" id=code.back>
<title>Back-matter
<description>Handles notes, bibliography and indexing

<![ ignore [
<codereference doc="slnavig.dsl" id=code.navig>
<title>Navigation code
<description>
Code to support the generation of HTML filenames, and the
links which navigate between documents

<codereference doc="slhtml.dsl" id=code.html>
<title>HTML support
<description>
Code to support HTML generation

<codereference doc="sltables.dsl" id=code.tables>
<title>Tables support
<description>
Simple support for tables.

<codereference doc="sllinks.dsl" id=code.links>
<title>Inter- and Intra-document linking
<description>Handles <code/ref/, <code/docxref/, <code/webref/ and <code/url/.
Imposes the link policy.

]]>


<codegroup 
  use="code.lib code.common code.maths code.back" 
  id=html>
<title>HTML-specific stylesheet code
<description>
This is the DSSSL stylesheet for converting the Starlink DTD to HTML.

<misccode>
<description>Declare the flow-object-classes to support the SGML
transformation extensions of Jade.</description>
<codebody>
(declare-flow-object-class element
  "UNREGISTERED::James Clark//Flow Object Class::element")
(declare-flow-object-class empty-element
  "UNREGISTERED::James Clark//Flow Object Class::empty-element")
(declare-flow-object-class document-type
  "UNREGISTERED::James Clark//Flow Object Class::document-type")
(declare-flow-object-class processing-instruction
  "UNREGISTERED::James Clark//Flow Object Class::processing-instruction")
(declare-flow-object-class entity
  "UNREGISTERED::James Clark//Flow Object Class::entity")
(declare-flow-object-class entity-ref
  "UNREGISTERED::James Clark//Flow Object Class::entity-ref")
(declare-flow-object-class formatting-instruction
  "UNREGISTERED::James Clark//Flow Object Class::formatting-instruction")
(define debug
  (external-procedure "UNREGISTERED::James Clark//Procedure::debug"))

(define %stylesheet-version%
  "Starlink HTML Stylesheet version 0.1")

<!-- include the other parts by reference -->

&slroutines.dsl
&sldocs.dsl
&slsect.dsl
&slmisc.dsl
&slparams.dsl
&slhtml.dsl
&slnavig.dsl
&sltables.dsl
&sllinks.dsl

<misccode>
<description>
The root rule.  This generates the HTML documents, then generates the
manifest and extracts the maths to an external document for postprocessing.
<codebody>
(root
 (make sequence
   (process-children)
   (make-manifest)
   (get-maths)
   ))

<func>
<routinename>make-manifest
<description>Construct a list of the HTML files generated by the main
processing.  Done only if <code/suppress-manifest/ is false and 
<code/%html-manifest%/ is true, giving the
name of a file to hold the manifest.  
<p>Add "figurecontent" and "backmatter" to the list
of elements in (chunk-element-list), and treat them specially.
Those elements should have suitable FO construction rules defined within 
mode `make-manifest-mode'.
<p>The codecollection and docxref elements also have
attributes with ENTITY declared values.  Should I worry about those?
<returnvalue none>
<argumentlist>
<parameter optional default='(current-node)'>nd<type>singleton-node-list
  <description>Node which identifies the grove to be processed.
<codebody>
(define (make-manifest #!optional (nd (current-node)))
  (if (and %html-manifest% (not suppress-manifest))
      (let ((element-list (append (chunk-element-list)
				  (list (normalize "figure")
					(normalize "coverimage")
					(normalize "backmatter")
					(normalize "m")
					(normalize "mequation")
					(normalize "meqnarray"))))
	    (rde (document-element nd)))
	(make entity system-id: %html-manifest%
	      (with-mode make-manifest-mode
		(process-node-list
		 (node-list rde		;include current file
			    (node-list-filter-by-gi
			     (select-by-class (descendants rde)
					      'element)
			     element-list))))))
      (empty-sosofo)))

(mode make-manifest-mode
  (default 
    (make sequence
      (make formatting-instruction data: (html-file))
      (make formatting-instruction data: "
")
      ))

  (element backmatter
    (make sequence
      (make fi data: (string-append (html-file) "
"))					; that one's easy
      (if (hasnotes?)
	  (make fi data: (string-append (notes-sys-id) "
"))
	  (empty-sosofo))
      (if (hasbibliography?)
	  (make fi data: (string-append (bibliography-sys-id) "
"))
	  (empty-sosofo))
      (if (hashistory?)
	  (make fi data: (string-append (updatelist-sys-id) "
"))
	  (empty-sosofo))))

  ;; The selection here should match the processing in slmisc.dsl
  (element figure
    (let* ((kids (children (current-node)))
	   (content (get-best-figurecontent
		     (select-elements kids (normalize "figurecontent"))
		     '("GIF89A" "JPEG"))))
      (if content
	  (process-node-list content)
	  (empty-sosofo))))
  (element coverimage
    (let* ((kids (children (current-node)))
	   (content (get-best-figurecontent
		     (select-elements kids (normalize "figurecontent"))
		     '("GIF89A" "JPEG"))))
      (if content
	  (process-node-list content)
	  (empty-sosofo))))
  ;; the figurecontent element writes out TWO fields in the manifest:
  ;; the first is the sysid of the figure as referred to by the
  ;; generated HTML, which will have no path, and the second is the sysid as
  ;; declared in the entity, which may well have a path.  Locations may
  ;; need some post-processing.
  (element figurecontent
    (let* ((image-ent (attribute-string (normalize "image")
					(current-node)))
	   (full-sysid (and image-ent
			    (entity-system-id image-ent)))
	   (base-sysid (and image-ent
			    (car (reverse
				  (tokenise-string
				   (entity-system-id image-ent)
				   boundary-char?: (lambda (c)
						     (char=? c #\/))))))))
      (if image-ent
	  (make fi data: (string-append base-sysid " " full-sysid "
"))
	  (empty-sosofo))))
  (element m
    (make fi data: (string-append (img-equation-sysid (current-node)) "
")))
  (element mequation
    (make fi data: (string-append (img-equation-sysid (current-node)) "
")))
  (element meqnarray
    (make fi data: (string-append (img-equation-sysid (current-node)) "
")))
  )

<codegroup>
<title>The default rule
<description>This has to be in a separate group
(<code/style-specification/ in the terms of the DSSSL architecture),
so that it doesn't take priority over mode-less rules in other process
specification parts.  See the DSSSL standard, sections 7.1 and 12.4.1.
<misccode>
<description>The default rule
<codebody>
(default
  (process-children))
;; Make text that comes from unimplemented tags easy to spot
;(default
;  (make element gi: "FONT"
;	attributes: '(("COLOR" "RED"))
;	(make entity-ref name: "lt")
;	(literal (gi))
;	(make entity-ref name: "gt")
;	(process-children)
;	(make entity-ref name: "lt")
;	(literal "/" (gi))
;	(make entity-ref name: "gt")
;	))
