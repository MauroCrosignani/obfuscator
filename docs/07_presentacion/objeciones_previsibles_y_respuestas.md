# Objeciones Previsibles y Respuestas

## Proposito

Anticipar preguntas u objeciones del publico tecnico y preparar respuestas apoyadas en decisiones del producto.

## Objeciones semilla

### "¿No alcanza con sacar identificadores directos?"

No. En datasets anchos o conocidos por el tercero, la identidad puede reconstruirse por combinacion de atributos y por reenlazabilidad con la fuente original.

### "¿Por que bloquear exportaciones?"

Porque una herramienta de liberacion segura debe ser defendible. Si no puede justificar la salida, no deberia delegar esa responsabilidad a un clic superficial del usuario.

### "Si la app genera codigo R, ¿no significa que el dataset ya es compartible?"

No. El codigo generado sirve para reproducir transformaciones internas y auditar configuraciones, pero la liberacion externa sigue siendo una decision separada. Poder ejecutar un script no equivale a cumplir automaticamente las condiciones de liberacion segura.
