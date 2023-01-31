REQUISITOS: tener GNATStudio instalado, python en cualquier versión 3 o superior, gcov/gcovr, los módulos z3-solver, numpy y random de python y una jerarquía de archivos en GNAT.

1) Instalar GNATStudio.

2) En mi caso concreto, lo ejecuto con python 3.10.8 pero cualquier python de versión 3 o superior debería valer. Importante que no se use una versión 2 ya que el tratamiento de strings cambia respecto a python 3.

3) En lo que a gcov/gcovr respesta, gcov ya venía junto con el paquete básico de gcc pero gcovr sí requiere instalación:
https://gcovr.com/en/stable/installation.html
Una prueba fácil para ver si efectivamente se dispone de gcov sería ejecutar desde Git: "gcov --help" y luego "gcovr --help" para confirmar que ambos se hallen presentes.

4) En cuanto a Z3, random y numpy, son módulos de python por lo que bastaría con hacer un pip install z3-solver numpy random. Página de referencia del módulo de z3: https://pypi.org/project/z3-solver

5) También es necesario tener la siguiente jerarquía de archivos en GNAT: /GNAT/2021/projects/Test_Generator/, y dentro de la carpeta Test_Generator incluir todo el contenido descargado de este repositorio.

6) Dado que Github no soporta archivos demasiado pesados no pude subir el ejecutable del LAL_Test_Oracle, por lo que el proyecto de LAL_Test_Oracle requiere compilarse.

USO: tras cumplir los requisitos previos,

1) Descargar el contenido del repositorio.

2) Dentro de la carpeta LAL_TestOracle, abrir LAL_Test_Oracle.gpr con GNATStudio y compilarlo.

3) Volver a la carpeta principal y ejecutar el script Execute_All_Case_Studies.sh.
