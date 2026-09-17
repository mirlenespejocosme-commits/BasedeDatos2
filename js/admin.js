const REPO_OWNER = 'mirlenespejocosme-commits';
const REPO_NAME = 'BasedeDatos2';

let githubToken = localStorage.getItem('github_token');
let portfolioData = null;
let datosJsonSha = null;

if (!githubToken) {
    alert('No estás autenticado.');
    window.location.href = 'index.html';
}

document.addEventListener('DOMContentLoaded', loadData);

function logout() {
    localStorage.removeItem('github_token');
    window.location.href = 'index.html';
}

async function fetchFromGithub(path) {
    const res = await fetch(`https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${path}`, {
        headers: {
            'Authorization': `token ${githubToken}`,
            'Accept': 'application/vnd.github.v3+json'
        }
    });
    if (!res.ok) throw new Error('Error al conectar con GitHub. Verifica tu Token.');
    return res.json();
}

async function loadData() {
    try {
        const fileData = await fetchFromGithub('datos.json');
        datosJsonSha = fileData.sha;
        const decodedContent = decodeURIComponent(escape(atob(fileData.content)));
        portfolioData = JSON.parse(decodedContent);
        renderAdmin();
    } catch (e) {
        alert(e.message);
        console.error(e);
    }
}

function renderAdmin() {
    document.getElementById('presentacion-texto').innerText = portfolioData.presentacion;

    const container = document.getElementById('unidades-container');
    let html = '';

    portfolioData.unidades.forEach((unidad, uIdx) => {
        html += `
            <details class="unidad" open>
                <summary>${unidad.titulo}</summary>
                <div class="semanas-grid">
        `;

        unidad.semanas.forEach((semana, sIdx) => {
            html += `
                <div class="semana-card">
                    <h4>${semana.titulo}</h4>
                    <p contenteditable="true" onblur="updateDesc(${uIdx}, ${sIdx}, this.innerText)" style="border:1px dashed #ccc; padding:5px;">${semana.descripcion}</p>
            `;
            
            semana.actividades.forEach((act, aIdx) => {
                html += `
                    <div style="margin-top:10px; padding:5px; background:#f9f9f9; border-radius:4px;">
                        <a href="${act.archivo}" target="_blank">${act.nombre}</a>
                        <button onclick="borrarActividad(${uIdx}, ${sIdx}, ${aIdx})" class="btn-sm btn-danger" style="float:right;">X</button>
                    </div>
                `;
            });

            html += `
                    <div class="admin-controls">
                        <button onclick="openModal(${uIdx}, ${sIdx})" class="btn btn-sm">➕ Añadir Archivo</button>
                    </div>
                </div>
            `;
        });

        html += `
                </div>
            </details>
        `;
    });

    container.innerHTML = html;
}

function updateDesc(uIdx, sIdx, newText) {
    portfolioData.unidades[uIdx].semanas[sIdx].descripcion = newText;
}

function editarPresentacion() {
    const newText = prompt("Edita tu presentación:", portfolioData.presentacion);
    if (newText !== null) {
        portfolioData.presentacion = newText;
        renderAdmin();
    }
}

function borrarActividad(uIdx, sIdx, aIdx) {
    if (confirm('¿Seguro que quieres borrar esta actividad?')) {
        portfolioData.unidades[uIdx].semanas[sIdx].actividades.splice(aIdx, 1);
        renderAdmin();
    }
}

function openModal(uIdx, sIdx) {
    document.getElementById('modal-unidad-idx').value = uIdx;
    document.getElementById('modal-semana-idx').value = sIdx;
    document.getElementById('act-nombre').value = '';
    document.getElementById('act-file').value = '';
    document.getElementById('modal-actividad').style.display = 'block';
}

function closeModal(id) {
    document.getElementById(id).style.display = 'none';
}

async function guardarActividad() {
    const uIdx = document.getElementById('modal-unidad-idx').value;
    const sIdx = document.getElementById('modal-semana-idx').value;
    const nombre = document.getElementById('act-nombre').value;
    const fileInput = document.getElementById('act-file');

    if (!nombre) {
        alert('Ponle un nombre a la actividad');
        return;
    }

    let fileName = "#";

    if (fileInput.files.length > 0) {
        const file = fileInput.files[0];
        // Clean filename
        fileName = file.name.replace(/\s+/g, '_');
        
        showLoading(true);
        try {
            const base64Data = await fileToBase64(file);
            await uploadFileToGithub(fileName, base64Data.split(',')[1]);
        } catch (e) {
            alert('Error subiendo el archivo: ' + e.message);
            showLoading(false);
            return;
        }
    } else {
        fileName = prompt("Si no subes archivo, ingresa la URL o deja #", "#");
    }

    portfolioData.unidades[uIdx].semanas[sIdx].actividades.push({
        nombre: nombre,
        archivo: fileName
    });

    closeModal('modal-actividad');
    renderAdmin();
    
    if (fileInput.files.length > 0) {
        // Automatically save json after uploading a file
        await saveToGithub();
        showLoading(false);
        alert('Archivo subido y base de datos actualizada.');
    }
}

function fileToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = () => resolve(reader.result);
        reader.onerror = error => reject(error);
    });
}

async function uploadFileToGithub(fileName, base64Content) {
    const body = {
        message: `Admin: Subiendo archivo ${fileName}`,
        content: base64Content
    };

    // Check if file exists to get SHA (for overwrite)
    try {
        const existing = await fetchFromGithub(fileName);
        body.sha = existing.sha;
    } catch(e) {
        // Doesn't exist, fine
    }

    const res = await fetch(`https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/${fileName}`, {
        method: 'PUT',
        headers: {
            'Authorization': `token ${githubToken}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(body)
    });

    if (!res.ok) throw new Error('Falló la subida a GitHub');
}

async function saveToGithub() {
    showLoading(true);
    try {
        const jsonString = JSON.stringify(portfolioData, null, 2);
        const base64Content = btoa(unescape(encodeURIComponent(jsonString)));

        const body = {
            message: 'Admin: Actualizando base de datos del portafolio',
            content: base64Content,
            sha: datosJsonSha
        };

        const res = await fetch(`https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/contents/datos.json`, {
            method: 'PUT',
            headers: {
                'Authorization': `token ${githubToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body)
        });

        if (!res.ok) throw new Error('Error al guardar datos.json');
        
        const responseData = await res.json();
        datosJsonSha = responseData.content.sha; // Update SHA
        
        alert('¡Cambios guardados exitosamente en GitHub!');
    } catch(e) {
        alert(e.message);
    }
    showLoading(false);
}

function showLoading(show) {
    document.getElementById('loading-overlay').style.display = show ? 'block' : 'none';
}
