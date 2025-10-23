// Please see documentation at https://learn.microsoft.com/aspnet/core/client-side/bundling-and-minification
// for details on configuring this project to bundle and minify static web assets.

// Write your JavaScript code.

function getAntiForgeryToken() {
	const tokenField = document.querySelector('input[name="__RequestVerificationToken"]');
	return tokenField ? tokenField.value : '';
}

async function handleFavoriteToggle(button) {
	const productId = button.dataset.productId;
	if (!productId) {
		return;
	}

	const token = getAntiForgeryToken();
	if (!token) {
		console.warn('Missing anti-forgery token.');
		return;
	}

	try {
		const response = await fetch('/Favorites/Toggle', {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
				'RequestVerificationToken': token
			},
			body: JSON.stringify({ productId: parseInt(productId) })
		});

		if (response.status === 401 || (response.redirected && response.url.includes('/Identity/Account/Login'))) {
			window.location.href = '/Identity/Account/Login';
			return;
		}

		if (!response.ok) {
			throw new Error('Failed to toggle favorite');
		}

		const result = await response.json();
		if (!result?.success) {
			return;
		}

		const icon = button.querySelector('i');
		if (!icon) {
			return;
		}

		if (result.isFavorited) {
			icon.classList.remove('fa-regular');
			icon.classList.add('fa-solid', 'text-danger');
			button.title = 'Remove from Favorites';
			button.setAttribute('aria-label', 'Remove from Favorites');
		} else {
			icon.classList.remove('fa-solid', 'text-danger');
			icon.classList.add('fa-regular');
			button.title = 'Add to Favorites';
			button.setAttribute('aria-label', 'Add to Favorites');
		}
	} catch (error) {
		console.error('Favorite toggle failed', error);
	}
}

function initFavoriteToggles() {
	document.addEventListener('click', function (event) {
		const button = event.target.closest('.favorite-toggle');
		if (button) {
			event.preventDefault();
			handleFavoriteToggle(button);
		}
	});
}

document.addEventListener('DOMContentLoaded', function () {
	initFavoriteToggles();
});
