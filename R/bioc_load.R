bioc_load <- function(pkgname){
  biocpath <- file.path(gettmpdir(), "bioc_library");
  if(!file.exists(biocpath)){
    stopifnot(dir.create(biocpath));
  }
  
  pkgpath <- file.path(biocpath, pkgname);
  blockpath <- paste(pkgpath, "block", sep="_")
  
  #is there is a blocker but its old, we remove it. This should not happen.
  if(isTRUE(difftime(Sys.time(), file.info(blockpath)$mtime, units="secs") > config("timelimit.get")+5)){
    stopifnot(file.remove(blockpath, recursive=TRUE, force=TRUE));    
  }
  
  #wait for the block to disappear
  while(file.exists(blockpath)){
    Sys.sleep(1);
  }
  
  #see if it exists and if it is fresh enough
  if(file.exists(pkgpath)){
    return(pkgpath);      
  } 
  
  #make sure its gone
  unlink(pkgpath, recursive=TRUE, force=TRUE);    
  
  #setup a blocker (for concurrent requests to the same gist)
  stopifnot(file.create(blockpath));
  on.exit(unlink(blockpath, force=TRUE));
  
  #NOTE: for now we can't capture output from install.packages
  inlib(biocpath,
    tryCatch({
      if(pkgname == "BiocInstaller"){
        source("http://bioconductor.org/biocLite.R");
      } else {
        BiocInstaller::biocLite(pkgname);
      }
    }, error=function(e){
      stop("Package installation of ", pkgname, " failed: ", e$message);
    })
  );
  
  #check if package has been installed
  if(!file.exists(pkgpath)){
    stop("Package installation of ", pkgname, " was unsuccessful.");
  }
  
  #return the path 
  return(pkgpath);
}