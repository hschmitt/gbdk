#!/usr/bin/mawk -f

# astorgb.awk 0.2
# M.Hope 1999
# Simple AWK scripts that attempts to convert a GBDK/ASxxxx assembly file into
# something that rgbds can handle.
# Notes:
#   Must shift all globals to head of file
#   Sometimes drops BSS sections.
#   Doesnt handle anything more than simple expressions

function fixnumber( x )
{
	# Change 0x for $
	sub( "^0x", "$", x )
	sub( "^0b", "%", x )

	# Fix any < or > parts
	# > of abcd is ab
	# < of abcd is cd
	if (index(x,"<")) {
			x = "(" substr(x,2,100) "&$ff)"
	}
	if (index(x,">")) {
		x = "(" substr(x,2,100) ">>8)"
	}
	return x
}

function fixonearg( x )
{
	# Fix the first number in a list and return the fixed version only
	ret = fixnumber( fixlabel(substr( x, 1, index(x,",")-1)))
	if (ret=="") {
		ret = fixnumber( fixlabel(x) )
	}
	return ret
}

function fixmanyargs( x )
{
	ret = fixonearg(x)
	while (i=index(x,",")) {
		ret = ret "," fixonearg(substr(x,i+1,100))
		x = substr(x,i+1,100)
	}
	return ret
}

function fixlabel( x )
{
	# Change .label for label, label$ for .label
	if (index(x,".")==1) {
		ret = substr(x,2,100)
	}
	else {
		if (index(x, "$")>1) {
			ret = x
			gsub( /\$/, "", ret )
			ret = ".fi" ret
		}
		else {
			ret = x
		}
	}
	return ret
}

# Main?
{
	if (modename=="") {
		modname = "None"
	}
	if (sectname=="") {
		sectname= "CODE"
	}
	gsub( /\t/, " " )
#	gsub( "0x", "$" )	
#	gsub( "_CODE", "CODE" )
#	gsub( "\#<", "" )
#	gsub( "\#>", "" )
#	gsub( /\./, "" )		# . is a match all

	# Fix up any labels that start the line

	if (index($0," ")!=1) {
#	if (match($1,"\$\:")) {
#		temp = substr($1,0,2+index($1,"\$\:"))
#		$1="." temp ":"
		$1=fixlabel($1)
	}
	else {
		# Check to see if it's some kind of directive
		if (index($1,".")==1) {
			# Yes
			# Fix any = first
			if ($2=="=") {
				$0 = fixlabel($1) " EQU " fixnumber(fixlabel($3))
			} # xxx else?
			if ($1==".area") {
				$3=""
				$4=""
				$1="SECTION"
				if ($2=="_CODE") {
					$2="\"" modname modvers "\",CODE"
					modvers = modvers+1
					sectname="CODE"
				} else {
					if ($2=="_HEADER") {
						$2="\"" modname modvers "\",HOME"
						modvers = modvers+1
						sectname="HOME"
					}
					else {
						$0=""
					}
				}
			}
			if ($1==".org") {
				# Replace with section statement
				$0 = "SECTION \"" modname modvers "\"," sectname "[" fixnumber(fixlabel($2)) "]"
				modvers = modvers + 1
			}
			if ((substr($1,1,2)==".d")||(substr($1,1,2)==".b")) {
				# Some form of .db
				gsub( " .db", " DB" )
				gsub( " .ds", " DS" )
				gsub( " .byte", " DB" )
				gsub( " .dw", " DW" )
				gsub( " .blkb", "DS" )
				if ($1==".blkw") {
					$1 = "DS"
					$2 = $2*2
				}
				$0 = " " $1 " " fixmanyargs($2)
			}
			if ($1==".asciz") {
				$1 = "DB"
				$2 = $2 ",0"
			}
			
			gsub( " .include", "INCLUDE" )
			if ($1==".globl") {
				$1="GLOBAL"
				$2 = fixlabel($2)
			}
			
			if (index($1,".title")) {
				# Just comment it
				$1 = ";" substr($1,2,100)
			}
			if (index($1,".module")) {
				# Comment it and store the module name
				modname=$2
				$1 = ";" substr($1,2,100)
			}
				
		}
		else {
			# Just a normal line...
			gsub( /\(/, "[" )
			gsub( /\)/, "]" )
			gsub( /\#/, "" )
			op1 = substr($2,1,index($2,","))
			op2 = substr($2,index($2,",")+1,100)
			# print op2
			$2 = op1 fixmanyargs(op2)
			# print fixmanyargs(op2)
			if ($1 == "LDA") {
				if (match($2,"HL")) {
					# Recover the number
					$1 = " LD"
					temp = substr($2,index($2,",")+1,index($2,"[")-index($2,",")-1)
					$2 = "HL,[SP+" temp "]"
				}
				if (match($2,"SP,")) {
					# Recover the number
					$1 = " ADD"
					temp = substr($2,index($2,",")+1,index($2,"[")-index($2,",")-1)
					$2 = "SP," temp
				}
			} else {
				if ($1 == "LDH") {
					# Change LDH [xx],A to LD [$FF00+xx],A
					i1 = index($2,"[")
					i2 = index($2,"]")
					temp = substr($2,i1+1,i2-i1-1)
					temp = fixnumber(fixlabel(temp))

					$1 = "LD"
					$2 = substr($2,1,i1-1) "[$FF00+" temp "]" substr($2,i2+1,100)
				}
			}
			if (i1 = index( $2, "[")) {
				# Fix up any numbers or labels inside a []
				i2 = index($2,"]")
				temp = fixnumber( fixlabel( substr($2,i1+1,i2-i1-1)))
				$2 = substr($2,1,i1) temp substr($2,i2,100)
			}				
			$0 = " " $0
		}
	}
	print
}

