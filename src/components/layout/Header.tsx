'use client';
import React from 'react';
import Selections from './Selections';


export default function Header() {


	return (
		<header id="header">
			<h1>Pathfinding Visualizer</h1>

			<div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
				<Selections />

			</div>


		</header>
	);
}
