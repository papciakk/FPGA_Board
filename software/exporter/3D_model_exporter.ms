fn get_formatted_data data = (
	x0_s = formattedPrint data format:"05X"
	(substring x0_s (x0_s.count-3) (x0_s.count))
)

utility wireframe_exporter "Wireframe exporter" (
	button exportBtn "Export" width:250 autoDisplay:true \
	message:"Export scene objects"
	
	on exportBtn pressed do (
		out_name = GetSaveFileName types:"VHDL File(*.vhd)|*.vhd"
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
						
						format "use work.typedefs.all;\n\n" to:out_file
						format "package model is\n" to:out_file
						format "  constant MODEL_EDGES_NUMBER : integer := %;\n" numedges to:out_file
						format "  constant MODEL_DATA : mesh_data(% downto 0) := (\n" (numedges-1) to:out_file
						
						for i = 1 to numedges do (
							verts = polyOp.getEdgeVerts p i
							
							v1 = polyOp.getVert p verts[1]
							v2 = polyOp.getVert p verts[2]
							
							x0 = int(v1.x * 8191.0)
							y0 = int(v1.y * 8191.0)
							z0 = int(v1.z * 8191.0)
							x1 = int(v2.x * 8191.0)
							y1 = int(v2.y * 8191.0)
							z1 = int(v2.z * 8191.0)
							
							data_str = 
								(get_formatted_data x0) +
								(get_formatted_data y0) +
								(get_formatted_data z0) +
								(get_formatted_data x1) +
								(get_formatted_data y1) +
								(get_formatted_data z1)
							
							format "    X\"%\"" data_str to:out_file
							--format "    (to_signed(%, 16), to_signed(%, 16), to_signed(%, 16), to_signed(%, 16), to_signed(%, 16), to_signed(%, 16))" x0 y0 z0 x1 y1 z1 to:out_file
							
							if i != numedges then (
								format ",\n" to:out_file
							)
							else (
								format "\n" to:out_file
							)
							
						)
						
						format "  );\nend package;" to:out_file
						
						format "Exported % edges\n" numedges
						
					)
				)
			)
		)
		
		flush out_file
		close out_file
	)
)
