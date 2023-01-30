require 'strscan'
class Sound
    def initialize
        unless @file = ARGV[0]
            raise Exception, "ファイルがありません。"
        end
        # 予約後
        @keywords = {
            '+' => :add,
            '-' => :sub,
            '*' => :mul,
            '/' => :div,
            '(' => :left_parn,
            ')' => :right_parn,
            '=' => :equal,
            # '==' => :d_equal,
            '<' => :small,
            # '<=' => :s_equal,
            '>' => :big,
            # '>=' => :b_equal,
            'para' => :para,
            'real' => :real,
            'open' => :open,
            'close' => :close,
            'keepon' => :keepon,
            'visu' => :visu,
            'get' => :get,
            'true' => :true,
            'false' => :false
        }

        # 変数　@variable[変数] = 数値
        @variable = {}
        # ファイル読み込み
        read = File.read(@file)
        @scanner = StringScanner.new(read)

        # p sentences() # blockにするまで
        p execution(sentences()) # 実装
    end

    # [:block, 〜]の形にする。
    # 文列
    def sentences()
        unless s = sentence()
            raise Exception, "あるべき文が見つからない"
        end
        
        result = [:block, s]
        while s = sentence()
            result << s
        end
        # p result
        return result
    end

    def sentence()
        # 代入文、if文、while文、print文
        if token = para() then
            return token
        elsif token = keepon() then
            return token
        elsif token = visu() then
            return token
        elsif token = assignment() then
            return token
        end
    end

    # ソースコードの先頭から、次のtokenを一つ切り出して返す。
    def get_token()
        if scan = @scanner.scan(/\A\d+(?:\.\d+)?/) then #数値だったら
            # p "数値：#{scan}"
            return scan.to_f
        elsif scan = @scanner.scan(/\A*(#{@keywords.keys.map{|t| Regexp.escape(t)}.join('|')})/) then # 予約語だったら
            # p "予約語：#{@keywords[scan]}"
            return @keywords[scan]
        elsif scan = @scanner.scan(/\A[a-zA-Z]+/) then #英字だったら（変数名）
            # p "変数：#{scan}"
            return scan
        elsif scan = @scanner.scan(/\s/) then #改行文字
            scan = get_token()
            # p "改行の次：#{scan}"
            return scan
        end
    end

    # tokenを受け取り、ソースコードの先頭にそれを押し戻す。
    def unget_token()
        if !(@scanner.eos?) then
            @scanner.unscan
        end
    end
    
    # 式
    def expression()
        result = term()
        token = get_token()
        while token == :add or token == :sub
            result = [token, result, term()]
            token = get_token()
        end
        unget_token()
        # p result
        return result
    end

    def term()
        result = factor()
        token = get_token()
        while token == :mul or token == :div
            result = [token, result, factor()]
            token = get_token()
        end

        unget_token()
        return result
    end

    def factor()
        token = get_token()
        if token.is_a?(Float) then# 数字だったら
            result = token
        elsif token == :get then# 標準入力だったら
            result = token
        elsif token.is_a?(String) then# 数字だったら
            result = [:variable, token]
        elsif token == :left_parn then#（ だったら
            result = expression()
            token = get_token() # 閉じカッコを取り除く(使用しない)
            if token != :right_parn then# ) なかったら
                raise Exception, "構文エラー"
            else
                # p token
            end
        end

        return result
    end

    # if文
    def para()
        # if
        unless get_token() == :para
            unget_token()
            return nil
        end
        result = [:para]
        # 条件式
        unless token = conditions()
            raise Exception, "para_条件式がない"
        end
        result << token
        # then
        unless get_token() == :open
            raise Exception, "para_openがない"
        end

        
        # 式を取り出す
        unless token = sentence()
            raise Exception, "para_文がない"
        end
        result << token
        # 二文以上あった時
        while token = sentence() do
            result << token
        end

        # else　ない可能性あり
        if get_token() == :real then
            result2 = [:real]
            # 式を取り出す
            unless token = sentence()
                raise Exception, "para_real_文がない"
            end
            result2 << token
            # 二文以上あった時
            while token = sentence() do
                result2 << token
            end
        else
            unget_token()
        end

        # end
        unless get_token() == :close
            raise Exception, "para_closeがない"
            # closeの後に改行するか、別の文が続かないとエラーになってしまう。
        end
        
        result = result + [result2] if result2
        # p result
        return result
    end

    # 演算子 <,>,==,<=,>= と 真偽値 true,false
    def conditions()
        result = [:conditions]
        token = get_token() #変数
        unless token.instance_of?(String)
            raise Exception, "conditions_変数がない"
        end
        result << [:variable, token]

        is_d_equal = false
        token = get_token()
        case token
        when :small, :big
            token2 = get_token()
            if token2 == :equal then
                token = :b_equal if token == :big
                token = :s_equal if token == :small
                result << [:operator, token]
            else
                unget_token()
                result << [:operator, token]
            end
        when :equal
            is_d_equal = true
            token2 = get_token()
            if token2 == :equal then
                token = :d_equal
                result << [:operator, token]
            else
                raise Exception, "conditions_「=」→「==」にする"
            end
        else
            raise Exception, "conditions_演算子がない"
        end

        token = get_token()
        if token == :true then
            raise Exception, "#{@file}プログラムミス" if !is_d_equal
            result << token
        elsif token == :false then
            raise Exception, "#{@file}プログラムミス" if !is_d_equal
            result << token
        elsif token.instance_of?(String) then
            result << [:variable, token]
        elsif token.instance_of?(Float) then
            unget_token()
            unless token = expression()
                raise Exception, "conditions_式がない"
            end
            result << token
        else
            raise Exception, "conditions_変数または数値がない"
        end

        # p result
        return result
    end

    # while文
    def keepon
        # while
        unless get_token() == :keepon
            unget_token()
            return nil
        end
        result = [:keepon]

        # 条件式
        unless token = conditions()
            raise Exception, "keepon_条件式がない"
        end
        result << token

        # do
        unless get_token() == :open
            raise Exception, "keepon_openがない"
        end

        # 式を取り出す
        unless token = sentence()
            raise Exception, "keepon_文がない"
        end
        result << token
        # 二文以上あった時
        while token = sentence() do
            result << token
        end

        # end
        unless get_token() == :close
            raise Exception, "keepon_closeがない"
            # closeの後に改行するか、別の文が続かないとエラーになってしまう。
        end

        # p result
        return result
    end

    # print文
    def visu()
        unless get_token() == :visu
            unget_token()
            return nil
        end
        result = [:visu]

        token = get_token()
        if token == :get then
            result << token
        elsif token.instance_of?(String) then
            result << [:variable, token]
        elsif token.instance_of?(Float) then
            unget_token()
            unless token = expression()
                raise Exception, "visu_式がない"
            end
            result << token
        else
            raise Exception, "visu_変数または数値がない"
        end

        # p result
        return result
    end

    # 代入文
    def assignment()
        result = [:assignment]
        token = get_token()
        unless token.instance_of?(String)
            unget_token()
            return nil
        end

        result << [:variable, token]
        unless get_token() == :equal
            raise Exception, "イコールがない"
        end

        token = get_token()
        if token == :true || token == :false then
            result << token
        else
            unget_token()
            unless token = expression()
                raise Exception, "式がない"
            end
            result << token
        end
        # p result
        return result
    end

    ###############################################################################################################
    ###############################################################################################################

    # 実装 blockになった後の処理
    def execution(block)
        # p block
        if block.instance_of?(Array) then
            length = block.length
            for i in 1...length do
                blo = block[i]
                # p blo #ブロック全体で、1つ実行
                case blo[0]
                when :para
                    #次に来るのは、条件式（:conditions）
                    _para(blo)
                when :keepon
                    #次に来るのは、条件式（:conditions）
                    _keepon(blo)
                when :visu
                    #次に来るのは、変数（:variable）or 数値（Float）or 入力（:get）
                    _visu(blo)
                when :assignment
                    #次に来るのは、変数（:variable）
                    #イコールの右は、式（:add,:sub,:mul,:div）or 変数（:variable）or 数値（Float）or 入力（:get）
                    _assignment(blo)
                end
            end
        end
    end

    # 入力
    def _get()
        loop do
            get = STDIN.gets #数値か英字が入ってる
            @scanner = StringScanner.new(get)
            if scan = @scanner.scan(/\A\d+(\.\d+)?/) then #数値だったら（マイナスの数値は受け付けない）
                get = scan.to_f
            elsif scan = @scanner.scan(/\A[a-zA-Z]+/) then #英字だったら（変数名）
                get = scan
            else
                p "入力は半角英数字にしてください。（単語間の空白、マイナスの数値は×）"
            end

            return get if get != nil
        end
    end

    # 出力
    def _visu(blo)
        # p "visu"
        # p blo
        if blo[1].is_a?(Float) then
            puts blo[1]
        elsif  blo[1] == :get then
            get = _get()
        elsif blo[1][0] == :variable then
            if @variable[blo[1][1]] then
                puts @variable[blo[1][1]]
            else
                puts blo[1][1]
            end
        end
    end

    def _assignment(blo)
        # p "assignment"
        # p blo
        if blo[1][0] == :variable then
            if blo[2].is_a?(Float) then
                @variable[blo[1][1]] = blo[2]
            elsif blo[2] == :get then
                get = _get()#数値か英字が入ってる
                if get.is_a?(String) then
                    get = @variable[get] if @variable.key?(get)
                end
                @variable[blo[1][1]] = get
            elsif blo[2] == :true || blo[2] == :false
                @variable[blo[1][1]] = blo[2]
            elsif blo[2][0] == :variable then
                var = @variable[blo[2][1]]
                @variable[blo[1][1]] = var
            elsif blo[2][0] == :add || blo[2][0] == :sub || blo[2][0] == :mul || blo[2][0] == :div then
                @variable[blo[1][1]] = eval(blo[2])
            end
        end
        # p @variable #変数
    end

    def _para(blo)
        # p "para"
        # p blo
        len = blo.length
        if blo[1][0] == :conditions then
            if blo[1][3].is_a?(Float) then
                value = blo[1][3] 
            elsif blo[1][3] == :true || blo[1][3] == :false then
                value = blo[1][3]
            elsif blo[1][3][0] == :variable then
                value = @variable[blo[1][3][1]]
            end

            var = @variable[blo[1][1][1]] if blo[1][1][0] == :variable
            do_para = false
            if blo[1][2][0] == :operator then
                case blo[1][2][1]
                when :d_equal
                    do_para = true if var == value
                when :s_equal
                    do_para = true if var <= value
                when :b_equal
                    do_para = true if var >= value
                when :small
                    do_para = true if var < value
                when :big
                    do_para = true if var > value
                end
            end

            if do_para then
                k=0
                loop do
                    break if len == 2+k
                    break if blo[2+k].include?(:real)

                    if blo[2+k] == :get then
                        _get()
                    elsif blo[2+k][0] == :real then
                        break
                    elsif blo[2+k][0] == :visu then
                        _visu(blo[2+k])
                    elsif blo[2+k][0] == :assignment then
                        _assignment(blo[2+k])
                    elsif blo[2+k][0] == :keepon then
                        _keepon(blo[2+k])
                    elsif blo[2+k][0] == :para then
                        _para(blo[2+k])
                    end
                    k=k+1
                end
            else
                k=2
                do_real = false
                loop do
                    break if len == k
                    if blo[k].include?(:real) then
                        do_real = true
                        break
                    end
                    k=k+1
                end

                if do_real then
                    len = blo[k].length
                    for j in 0...len do
                        if blo[k][j] == :get then
                            _get()
                        elsif blo[k][j][0] == :visu then
                            _visu(blo[k][j])
                        elsif blo[k][j][0] == :assignment then
                            _assignment(blo[k][j])
                        elsif blo[k][j][0] == :keepon then
                            _keepon(blo[k][j])
                        elsif blo[k][j][0] == :para then
                            _para(blo[k][j])
                        end
                    end
                end
            end
        end
    end

    def _keepon(blo)
        # p "keepon"
        len = blo.length
        if blo[1][0] == :conditions then
            loop do
                var = @variable[blo[1][1][1]] if blo[1][1][0] == :variable
                if blo[1][3].is_a?(Float) then
                    value = blo[1][3]
                elsif blo[1][3][0] == :variable then
                    value = @variable[blo[1][3][1]] 
                end

                do_keepon = false
                if blo[1][2][0] == :operator then
                    case blo[1][2][1]
                    when :d_equal
                        do_keepon = true if var == value
                    when :s_equal
                        do_keepon = true if var <= value
                    when :b_equal
                        do_keepon = true if var >= value
                    when :small
                        do_keepon = true if var < value
                    when :big
                        do_keepon = true if var > value
                    end
                end

                break if do_keepon == false
                k=0
                loop do
                    break if len == k+2

                    if blo[2+k] == :get then
                            _get()
                    elsif blo[2+k][0] == :visu then
                        _visu(blo[2+k])
                    elsif blo[2+k][0] == :assignment then
                        block = blo[2+k]
                        if block[2][0] == :add || block[2][0] == :sub || block[2][0] == :mul || block[2][0] == :div then                        
                            if !block[2][1].is_a?(Float) then
                                variable1 = block[2][1][1]
                                value1 = @variable[variable1]
                            end
                            if !block[2][2].is_a?(Float) then
                                variable2 = block[2][2][1]
                                value2 = @variable[variable2]
                            end
                        end

                        _assignment(block)

                        if value1.is_a?(Float) then
                            block[2][1] = [:variable, variable1]
                        end
                        if value2.is_a?(Float) then
                            block[2][2] = [:variable, variable2]
                        end

                    elsif blo[2+k][0] == :keepon then
                        _keepon(blo[2+k])
                    elsif blo[2+k][0] == :para then
                        _para(blo[2+k])
                    end

                    k=k+1
                end
            end
        end
    end

    # 計算
    def eval(exp)
        if exp.instance_of?(Array) then
            case exp[0]
            when :add
                begin
                    exp[1] = @variable[exp[1][1]] if !exp[1].is_a?(Float) && exp[1].include?(:variable)
                    exp[2] = @variable[exp[2][1]] if !exp[2].is_a?(Float) && exp[2].include?(:variable)
                    return eval(exp[1]) + eval(exp[2])
                rescue => e
                    puts "加算でエラー：#{e.message}"
                end
            when :sub
                begin
                    exp[1] = @variable[exp[1][1]] if !exp[1].is_a?(Float) && exp[1].include?(:variable)
                    exp[2] = @variable[exp[2][1]] if !exp[2].is_a?(Float) && exp[2].include?(:variable)
                    return eval(exp[1]) - eval(exp[2])
                rescue => e
                    puts "減算でエラー：#{e.message}"
                end
            when :mul
                begin
                    exp[1] = @variable[exp[1][1]] if !exp[1].is_a?(Float) && exp[1].include?(:variable)
                    exp[2] = @variable[exp[2][1]] if !exp[2].is_a?(Float) && exp[2].include?(:variable)
                    return eval(exp[1]) * eval(exp[2])
                rescue => e
                    puts "乗算でエラー：#{e.message}"
                end
            when :div
                begin
                    exp[1] = @variable[exp[1][1]] if !exp[1].is_a?(Float) && exp[1].include?(:variable)
                    exp[2] = @variable[exp[2][1]] if !exp[2].is_a?(Float) && exp[2].include?(:variable)
                    return eval(exp[1]) / eval(exp[2])
                rescue => e
                    puts "除算_でエラー：#{e.message}"
                end
            end
        else
            return exp
        end
    end
end


Sound.new