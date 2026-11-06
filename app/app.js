// Importamos el framework Express para crear el servidor web de forma sencilla
const express = require('express');
const app = express();

// Definimos el puerto en el que va a escuchar nuestra aplicación
// Si existe una variable de entorno llamada PORT (típica en producción), la usa; si no, usa el puerto 3000 por defecto.
const PORT = process.env.PORT || 3000;

// Definimos una ruta básica (Endpoint GET en la raíz '/')
app.get('/', (req, res) => {
  res.json({
    message: "¡Hola desde el contenedor Docker en tu proyecto DevOps End-to-End!",
    status: "Success",
    timestamp: new Date()
  });
});

// Iniciamos el servidor escuchando en todas las interfaces de red (0.0.0.0)
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Servidor corriendo y escuchando en el puerto ${PORT}`);
});