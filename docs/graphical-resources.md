# Graphical Resources

By now, you have learned to use the following objects

- Mesh
- Texture
- Surface

Even even `Shader` if you go native by mixing it with your own OpenGL commands
and rendering pipeline programs.

What was not said is that they are have a common property: they are graphical 
objects, meaning that they have internal states with the graphics driver.

Your BEAM processes are exepcted to crash and proper cleanup need to happen.

## Resource ownership

When a graphical resource is created as with one of the new/x function, the 
BEAM process becomes the owner of that resource.

The BEAM process has a one-way link with the graphical resources dispenser 
which will destroy the resource if the BEMA process die.

You must transfer the resource with one of the 
`transfer_ownership/x` function.

Furthermore, if the graphical resource dispenser crashes, it will take down 
all the BEAM processes that have.

> Think about it. If the BEAM process manipulating the graphical resource 
> dies, it can be restarted and re-acquire a new one just fine. However, if the 
> opposite happens, all BEAM process owner resources should just die as.
