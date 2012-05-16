all: mazurov-chep2012.pdf

show: mazurov-chep2012.pdf
	evince mazurov-chep2012.pdf&

mazurov-chep2012.pdf: mazurov-chep2012.tex figs/*.png
	pdflatex mazurov-chep2012.tex && pdflatex mazurov-chep2012.tex

clean:
	rm *.pdf *.aux *.log
