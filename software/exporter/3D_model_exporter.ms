utility wireframe_exporter "Wireframe exporter" (
	button exportBtn "Export" width:250 autoDisplay:true \
	message:"Export scene objects"
	
	on exportBtn pressed do (
		out_name = GetSaveFileName types:"Text file(*.txt)|*.txt"
		out_file = createFile out_name
		
		if out_file  != undefined then (		
			for obj in Geometry do (
				if obj != undefined do (	
					if (superClassOf obj == geometryClass) then (						
						ratios = [1, 1, 1]/(obj.max-obj.min)
						scale_factor = amin #(ratios.x, ratios.y, ratios.z)
						
						p = convertToPoly(obj)
						scale p  (scale_factor * [2, 2, 2])
						p.pivot = p.center
						p.pos = [0,0,0]
					
						numedges = polyOp.getNumEdges p
						format "Exporting % edges\n" numedges
						
						for i = 1 to numedges do (
							verts = polyOp.getEdgeVerts p i
							for v in verts do (
								pos = polyOp.getVert p v
								xn = int(pos.x * 8191.0)
								yn = int(pos.y * 8191.0)
								zn = int(pos.z * 8191.0)
								
								print xn to:out_file
								print yn to:out_file
								print zn to:out_file
							)
						)
						
						format "Done!\n"
						
					)
				)
			)
		)
		
		flush out_file
		close out_file
	)
)
