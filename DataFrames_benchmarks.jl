### A Pluto.jl notebook ###
# v0.19.26

using Markdown
using InteractiveUtils

# ╔═╡ be640384-0945-11ee-217a-35c78a2884e0
using PyCall , PlutoUI, DataFrames, CSV, BenchmarkTools, JSON

# ╔═╡ b12b2b13-caa1-426f-b80b-08886a10fddb
md""" ## Pandas, Polars, Julia DataFrame Benchmarks
"""

# ╔═╡ a226c07d-9625-41ee-b8f6-a946bd6c50b5
if false
	run(`$(PyCall.python) -m pip install --upgrade pip`)
	run(`$(PyCall.python) -m pip install polars pandas`)
end

# ╔═╡ 35aea64c-3805-413a-bdf0-f8e66cf9ef11
begin
	pd = pyimport("pandas")
	pl = pyimport("polars")
end

# ╔═╡ 8b91d461-e46c-47a0-9e91-d65edc2d70eb
begin
	println("Pandas version:\t", pd.__version__)
	println("Polars version:\t", pl.__version__)
	println("Julia version:\t", VERSION)
end

# ╔═╡ f3a042c4-86a9-4aac-9409-e3f59d1bd502
md""" ### Ingest CSV File
"""

# ╔═╡ 8360e30d-9775-43f8-9f3d-ae637f26146d
b_i_1 = @benchmark pd.read_csv("dataset.csv")

# ╔═╡ be981e6f-77bb-4ea5-ad8b-df2679a02b9a
b_i_2 = @benchmark pl.read_csv("dataset.csv")

# ╔═╡ 70f7179e-8264-4b03-b420-6056137b1f35
b_i_3 = @benchmark CSV.read("dataset.csv", DataFrame)

# ╔═╡ b70b41fe-17e2-416a-86a4-ff424e82eb87
begin
	df_pd = pd.read_csv("dataset.csv")
	df_pl = pl.read_csv("dataset.csv")
	df_jl = CSV.read("dataset.csv", DataFrame)
end

# ╔═╡ b9ebe150-20d1-403d-866b-7aa9426682dd
md""" ### Write to CSV File
"""

# ╔═╡ 7eef3b74-67cd-4a5f-a3d4-c46f14b9c375
b_w_1 = @benchmark df_pd.to_csv("dataset_dummy_pandas.csv")

# ╔═╡ e1a31d97-4ce6-4210-9eab-266e126b81c5
b_w_2 = @benchmark df_pl.write_csv("dataset_dummy_polars.csv")

# ╔═╡ 4cb70ec5-0f63-435c-950a-2c07268df674
b_w_3 = @benchmark CSV.write("dataset_dummy_julia.csv", df_jl)

# ╔═╡ 8237abd1-2e50-44cb-b6ce-669e82bea126
md""" ### Memory Allocation
"""

# ╔═╡ be9129d1-862a-4ba7-8755-028b297f8a46
md""" Estimation of the total (heap) allocated size of the DataFrame
"""

# ╔═╡ 7354b274-4f98-4be1-98e5-b07c30595329
# df_pd.info(memory_usage="deep")
m_1 = df_pd.memory_usage(deep=true).sum() * 1e-9 # GB

# ╔═╡ cd590e5d-48bc-4a16-ba56-93a4081c964f
m_2 = df_pl.estimated_size("gb") # GB

# ╔═╡ 9f144c7c-1afd-44d0-8643-3c7a5034f053
m_3 = Base.summarysize(df_jl) * 1e-9 # GB

# ╔═╡ 4b18a08c-2286-440f-804b-cccc904228e8
md""" ### Selecting Columns
"""

# ╔═╡ bbb0a3b0-1a5c-4c9e-a68c-89b6e7d36604
# df_pd.columns
b_c_1 = @benchmark get(df_pd, py"['Name', 'Employee_Rating']")

# ╔═╡ 16038a29-6a65-40c6-9555-4eb6973348f4
b_c_2 = @benchmark get(df_pl, py"['Name', 'Employee_Rating']")

# ╔═╡ dbd69695-84a6-4cf5-94a9-e06ce546c7e2
b_c_3 = @benchmark df_jl[!,[:Name,:Employee_Rating]]

# ╔═╡ 22152a33-e19a-4718-88fb-d48e006853aa
md""" ### Filtering
"""

# ╔═╡ bdce368d-4277-4aaf-beeb-3f99a22d65fd
b_f_1 = @benchmark get(df_pd, df_pd.Credits>2)

# ╔═╡ 6fd84710-e40e-42c9-9515-72b1c413c0f4
b_f_2 = @benchmark df_pl.filter(pl.col("Credits") > 2)

# ╔═╡ de0f17bb-8510-451b-ba26-e8f3a0cceaf0
b_f_3 = @benchmark filter([:Credits] => (x) -> x .> 2, df_jl)

# ╔═╡ 7c1a8f64-0304-41a4-86d8-cc5b9633d6df
md""" ### Grouping
"""

# ╔═╡ 231d9db0-6b08-412d-94f8-17e75e164393
b_g_1 = @benchmark df_pd.groupby("Company_Name").Employee_Salary.mean().reset_index()

# ╔═╡ e185aa68-66d5-4549-9f94-9622aee39960
b_g_2 = @benchmark df_pl.groupby("Company_Name").agg(pl.mean("Employee_Salary"))

# ╔═╡ 21b03cc4-56be-47c3-971f-a3d599fb50db
b_g_3 = @benchmark combine(groupby(df_jl, :Company_Name), [:Employee_Salary] .=> mean; renamecols=false)

# ╔═╡ 38a41a9c-5740-4724-9199-e34d9ffe51c5
md""" ### Sorting
"""

# ╔═╡ 88820b7b-db6f-4023-93bc-6faf36e61509
b_s_1 = @benchmark df_pd.sort_values("Employee_Salary")

# ╔═╡ 286f2c5f-22d0-4dd1-acc3-0d005c1be634
b_s_2 = @benchmark df_pl.sort("Employee_Salary")

# ╔═╡ ef3942fa-214f-4527-ab65-6bec0df79403
b_s_3 = @benchmark sort!(df_jl, :Employee_Salary, rev=false)

# ╔═╡ 29331c71-bf08-4135-a0e2-74ec2da65ae5
md""" ## Benchmark Results
"""

# ╔═╡ 5b430d7d-42ec-407b-a7d3-2a65cccc2db7
r(x) = round(x; digits=1) 

# ╔═╡ 5ef2b97b-4ff3-4d3e-8737-a089c58c304c
md"""
| DataFrames : $(size(df_jl)[1]) × $(size(df_jl)[2]) | Pandas v"$(pd.__version__)" | Polars v"$(pl.__version__)" | Julia $(VERSION) | (median rel. Pandas) |
| :-------: | :----: | :----: | :---: | :---: |
| CSV Ingestion | $(r(median(b_i_1.times)*1e-9)) sec | $(r(median(b_i_2.times)*1e-9)) sec | $(r(median(b_i_3.times)*1e-9)) sec | Julia $(r(median(b_i_1.times)/median(b_i_3.times)))x, Polars $(r(median(b_i_1.times)/median(b_i_2.times)))x faster |
| Memory Utilization | $(r(m_1)) GB | $(r(m_2)) GB | $(r(m_3)) GB | Julia $(r(m_1/m_3))x, Polars $(r(m_1/m_2))x more memory efficient |
| CSV Write | $(r(median(b_w_1.times)*1e-9)) sec | $(r(median(b_w_2.times)*1e-9)) sec | $(r(median(b_w_3.times)*1e-9)) sec | Julia $(r(median(b_w_1.times)/median(b_w_3.times)))x, Polars $(r(median(b_w_1.times)/median(b_w_2.times)))x faster |
| Column Selection | $(r(median(b_c_1.times)*1e-6)) μsec | $(r(median(b_c_2.times)*1e-3)) msec | $(r(median(b_c_3.times)*1e0)) nsec | Julia $(r(median(b_c_1.times)/median(b_c_3.times)))x, Polars $(r(median(b_c_1.times)/median(b_c_2.times)))x faster |
"""

# ╔═╡ c32d9e3d-1ac8-48f2-8c9d-d363fecf5336
b_c_3.times

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
JSON = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
PyCall = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"

[compat]
BenchmarkTools = "~1.3.2"
CSV = "~0.10.11"
DataFrames = "~1.5.0"
JSON = "~0.21.4"
PlutoUI = "~0.7.51"
PyCall = "~1.95.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.1"
manifest_format = "2.0"
project_hash = "a35d0bb880e62386f7c0bec132401cbc627c6fdd"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "d9a9701b899b30332bbcb3e1679c41cce81fb0e8"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.2"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "44dbf560808d49041989b8a96cae4cffbeb7966a"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.11"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "9c209fb7536406834aa938fb149964b985de6c83"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "7a60c856b9fa189eb34f5f8a6f6b5529b7942957"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.6.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.2+0"

[[deps.Conda]]
deps = ["Downloads", "JSON", "VersionParsing"]
git-tree-sha1 = "915ebe6f0e7302693bdd8eac985797dba1d25662"
uuid = "8f4d0f93-b110-5947-807f-2305c1781a2d"
version = "1.9.0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SnoopPrecompile", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "aa51303df86f8626a962fccb878430cdb0a97eee"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.5.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates", "Mmap", "Printf", "Test", "UUIDs"]
git-tree-sha1 = "e27c4ebe80e8699540f2d6c805cc12203b614f12"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.20"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "d75853a0bdbfb1ac815478bacd89cd27b550ace6"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.3"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "42324d08725e200c23d4dfb549e0d5d89dede2d2"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.10"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OrderedCollections]]
git-tree-sha1 = "d321bf2de576bf25ec4d3e4360faca399afca282"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.0"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "b32107a634205cdcc64e2a3070c3eb0d56d54181"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.6.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "b478a748be27bd2f2c73a7690da219d0844db305"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.51"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "9673d39decc5feece56ef3940e5dafba15ba0f81"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.1.2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "7eb1686b4f04b82f96ed7a4ea5890a4f0c7a09f1"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "LaTeXStrings", "Markdown", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "213579618ec1f42dea7dd637a42785a608b1ea9c"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.4"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.PyCall]]
deps = ["Conda", "Dates", "Libdl", "LinearAlgebra", "MacroTools", "Serialization", "VersionParsing"]
git-tree-sha1 = "62f417f6ad727987c755549e9cd88c46578da562"
uuid = "438e738f-606a-5dbb-bf0a-cddfbfd45ab0"
version = "1.95.1"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "04bdff0b09c65ff3e06a05e3eb7b120223da3d39"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SnoopPrecompile]]
deps = ["Preferences"]
git-tree-sha1 = "e760a70afdcd461cf01a575947738d359234665c"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "a4ada03f999bd01b3a25dcaa30b2d929fe537e00"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.0"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "9a6ae7ed916312b41236fcef7e0af564ef934769"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.13"

[[deps.Tricks]]
git-tree-sha1 = "aadb748be58b492045b4f56166b5188aa63ce549"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.7"

[[deps.URIs]]
git-tree-sha1 = "074f993b0ca030848b897beff716d93aca60f06a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.2"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.VersionParsing]]
git-tree-sha1 = "58d6e80b4ee071f5efd07fda82cb9fbe17200868"
uuid = "81def892-9a0e-5fdd-b105-ffc91e053289"
version = "1.3.0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─b12b2b13-caa1-426f-b80b-08886a10fddb
# ╠═be640384-0945-11ee-217a-35c78a2884e0
# ╠═a226c07d-9625-41ee-b8f6-a946bd6c50b5
# ╟─35aea64c-3805-413a-bdf0-f8e66cf9ef11
# ╠═8b91d461-e46c-47a0-9e91-d65edc2d70eb
# ╟─f3a042c4-86a9-4aac-9409-e3f59d1bd502
# ╠═8360e30d-9775-43f8-9f3d-ae637f26146d
# ╠═be981e6f-77bb-4ea5-ad8b-df2679a02b9a
# ╠═70f7179e-8264-4b03-b420-6056137b1f35
# ╠═b70b41fe-17e2-416a-86a4-ff424e82eb87
# ╟─b9ebe150-20d1-403d-866b-7aa9426682dd
# ╠═7eef3b74-67cd-4a5f-a3d4-c46f14b9c375
# ╠═e1a31d97-4ce6-4210-9eab-266e126b81c5
# ╠═4cb70ec5-0f63-435c-950a-2c07268df674
# ╟─8237abd1-2e50-44cb-b6ce-669e82bea126
# ╟─be9129d1-862a-4ba7-8755-028b297f8a46
# ╠═7354b274-4f98-4be1-98e5-b07c30595329
# ╠═cd590e5d-48bc-4a16-ba56-93a4081c964f
# ╠═9f144c7c-1afd-44d0-8643-3c7a5034f053
# ╟─4b18a08c-2286-440f-804b-cccc904228e8
# ╠═bbb0a3b0-1a5c-4c9e-a68c-89b6e7d36604
# ╠═16038a29-6a65-40c6-9555-4eb6973348f4
# ╠═dbd69695-84a6-4cf5-94a9-e06ce546c7e2
# ╟─22152a33-e19a-4718-88fb-d48e006853aa
# ╠═bdce368d-4277-4aaf-beeb-3f99a22d65fd
# ╠═6fd84710-e40e-42c9-9515-72b1c413c0f4
# ╠═de0f17bb-8510-451b-ba26-e8f3a0cceaf0
# ╟─7c1a8f64-0304-41a4-86d8-cc5b9633d6df
# ╠═231d9db0-6b08-412d-94f8-17e75e164393
# ╠═e185aa68-66d5-4549-9f94-9622aee39960
# ╠═21b03cc4-56be-47c3-971f-a3d599fb50db
# ╟─38a41a9c-5740-4724-9199-e34d9ffe51c5
# ╠═88820b7b-db6f-4023-93bc-6faf36e61509
# ╠═286f2c5f-22d0-4dd1-acc3-0d005c1be634
# ╠═ef3942fa-214f-4527-ab65-6bec0df79403
# ╟─29331c71-bf08-4135-a0e2-74ec2da65ae5
# ╠═5ef2b97b-4ff3-4d3e-8737-a089c58c304c
# ╠═5b430d7d-42ec-407b-a7d3-2a65cccc2db7
# ╠═c32d9e3d-1ac8-48f2-8c9d-d363fecf5336
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
