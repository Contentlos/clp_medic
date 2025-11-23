// Added: simple NUI controller for death screen & EKG
const overlay = document.getElementById('overlay');
const ekgState = document.getElementById('ekg-state');
const dispatch = document.getElementById('dispatch');
const callList = document.getElementById('call-list');
const closeDispatchBtn = document.getElementById('dispatch-close');

function setState(state) {
    ekgState.classList.remove('unstable', 'flatline');
    let text = 'Stable';

    if (state === 'unstable') {
        text = 'Unstable';
        ekgState.classList.add('unstable');
    } else if (state === 'flatline') {
        text = 'Flatline';
        ekgState.classList.add('flatline');
    }

    ekgState.textContent = text;
}

function toggleOverlay(visible, state) {
    if (visible) {
        overlay.classList.remove('hidden');
    } else {
        overlay.classList.add('hidden');
    }
    if (state) {
        setState(state);
    }
}

function formatCoords(coords) {
    if (!coords) return 'Unknown';
    const { x = 0, y = 0, z = 0 } = coords;
    return `${x.toFixed(1)}, ${y.toFixed(1)}, ${z.toFixed(1)}`;
}

function renderCalls(calls = []) {
    callList.innerHTML = '';
    calls.forEach((call) => {
        const card = document.createElement('div');
        card.className = 'call-card';

        const assignedUnits = call.assigned ? Object.keys(call.assigned) : [];

        card.innerHTML = `
            <div class="header">
                <span>Call #${call.id || '?'} - ${call.reason || 'Dispatch'}</span>
                <span>${(call.status || 'waiting').toUpperCase()}</span>
            </div>
            <div class="meta">Caller: ${call.callerName || 'Unbekannt'} | Coords: ${formatCoords(call.coords)}</div>
            <div class="meta">Units: ${assignedUnits.length > 0 ? assignedUnits.join(', ') : 'Unassigned'}</div>
            <div class="actions">
                <button data-action="dispatch-status" data-id="${call.id}" data-status="assigned">Assign</button>
                <button class="secondary" data-action="dispatch-status" data-id="${call.id}" data-status="on_scene">On Scene</button>
                <button class="danger" data-action="dispatch-status" data-id="${call.id}" data-status="completed">Complete</button>
            </div>
        `;

        callList.appendChild(card);
    });
}

function toggleDispatch(visible, calls) {
    if (visible) {
        dispatch.classList.remove('hidden');
        renderCalls(calls || []);
    } else {
        dispatch.classList.add('hidden');
    }
}

function nui(eventName, data = {}) {
    fetch(`https://clp_medic/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    });
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'toggle') {
        toggleOverlay(data.visible, data.status);
    }

    if (data.action === 'setState') {
        setState(data.status);
    }

    if (data.action === 'dispatchOpen') {
        toggleDispatch(true, data.calls || []);
    }

    if (data.action === 'dispatchUpdate') {
        renderCalls(data.calls || []);
    }

    if (data.action === 'dispatchClose') {
        toggleDispatch(false);
    }
});

if (closeDispatchBtn) {
    closeDispatchBtn.addEventListener('click', () => {
        toggleDispatch(false);
        nui('dispatchClose');
    });
}

document.addEventListener('click', (event) => {
    const target = event.target;
    if (target && target.dataset && target.dataset.action === 'dispatch-status') {
        const id = Number(target.dataset.id);
        const status = target.dataset.status;
        nui('dispatchStatus', { id, status });
    }
});
