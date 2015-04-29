isdigit(){
	case $1 in
    		''|*[!0-9]*) return 1 ;;
		*) return 0 ;;
	esac

}
