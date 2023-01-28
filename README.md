REQUISITOS: tener python en cualquier versión 3 o superior, gcov/gcovr, los módulos z3-solver, numpy y random de python y una jerarquía de archivos en GNAT.

1) En mi caso concreto, lo ejecuto con python 3.10.8 pero cualquier python de versión 3 o superior debería valer. Importante que no se use una versión 2 ya que el tratamiento de strings cambia respecto a python 3.

2) En lo que a gcov/gcovr respesta, gcov ya venía junto con el paquete básico de gcc pero gcovr sí requiere instalación:
https://gcovr.com/en/stable/installation.html
Una prueba fácil para ver si efectivamente se dispone de gcov sería ejecutar desde Git: "gcov --help" y luego "gcovr --help" para confirmar que ambos se hallen presentes.
Utilidades como el "man" no vienen instaladas por defecto en Git pero con este truco del --help se puede consultar fácilmente si se dispone o no de algo.

3) En cuanto a Z3, random y numpy, son módulos de python por lo que bastaría con hacer un pip install z3-solver numpy random. Página de referencia del módulo de z3: https://pypi.org/project/z3-solver

4) También es necesario tener la siguiente jerarquía de archivos en GNAT: /GNAT/2021/projects/Test_Generator/, y dentro de la carpeta Test_Generator incluir el contenido de la carpeta homónima de mi github.

5) Dado que Github no soporta archivos demasiado pesados no pude subir el ejecutable del LAL_Test_Oracle, por lo que el proyecto de LAL_Test_Oracle requiere compilarse.

Bibliografía

Libadalang: https://docs.adacore.com/live/wave/libadalang/html/libadalang_ug/ada_api_core.html#package-Libadalang.Common

Z3py: https://ericpony.github.io/z3py-tutorial/guide-examples.htm
