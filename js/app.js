document.addEventListener('DOMContentLoaded', () => {
    fetch('datos.json')
        .then(response => response.json())
        .then(data => {
            document.getElementById('presentacion-texto').innerHTML = data.presentacion;

            const container = document.getElementById('unidades-container');
            let html = '';

            data.unidades.forEach((unidad, index) => {
                const isOpen = index === 0 ? 'open' : '';
                html += `
                    <details class="unidad" ${isOpen}>
                        <summary>${unidad.titulo}</summary>
                        <div class="semanas-grid">
                `;

                unidad.semanas.forEach(semana => {
                    html += `
                        <div class="semana-card">
                            <h4>${semana.titulo}</h4>
                            <p>${semana.descripcion}</p>
                    `;
                    
                    if(semana.carpetas && semana.carpetas.length > 0) {
                        semana.carpetas.forEach(carpeta => {
                            html += `
                                <div style="margin-top: 15px; border: 1px solid #ddd; padding: 10px; border-radius: 6px; background-color: #f4f6f9;">
                                    <h5 style="margin: 0 0 10px 0; color: #333;">📁 ${carpeta.nombre}</h5>
                            `;
                            if(carpeta.actividades && carpeta.actividades.length > 0) {
                                carpeta.actividades.forEach(act => {
                                    html += `<a href="${act.archivo}" target="_blank" class="btn" style="display:block; margin-top:5px; padding:5px; font-size:0.9rem;">${act.nombre}</a>`;
                                });
                            } else {
                                html += `<span style="font-size:0.8rem; color:#888;">Carpeta vacía</span>`;
                            }
                            html += `</div>`;
                        });
                    } else {
                        html += `<a href="#" class="btn" style="background-color: #ccc; cursor: not-allowed; display:block; margin-top:15px;">Próximamente</a>`;
                    }
                    html += `</div>`;
                });

                html += `
                        </div>
                    </details>
                `;
            });

            container.innerHTML = html;
        })
        .catch(error => {
            console.error('Error cargando los datos:', error);
            document.getElementById('presentacion-texto').innerText = 'Error al cargar los datos. Verifica que datos.json exista.';
        });
});
